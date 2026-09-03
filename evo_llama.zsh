: ${LLAMA_MODELS_DIR:=/DATA/SQA/LLM/models}
: ${LLAMA_API_KEY:=sk-no-key-required}

typeset -gx LLAMA_PORT=9931
typeset -gx LLAMA_BASE_URL="http://localhost:${LLAMA_PORT}/v1"

typeset -g LLAMA_MODEL_171="$LLAMA_MODELS_DIR/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"
typeset -g LLAMA_MODEL_172="$LLAMA_MODELS_DIR/qwen3.8-27b/Qwen3.8-27B-UD-Q8_K_XL.gguf"
typeset -g LLAMA_MODEL_LOCAL="$LLAMA_MODELS_DIR/Qwen3.6-35B-A3B-UD-IQ4_NL.gguf"

function _qwen_default_model() {
    local addresses=" $(hostname -I 2>/dev/null) "

    if [[ "$addresses" == *" 192.168.31.171 "* ]]; then
        print -r -- "$LLAMA_MODEL_171"
    elif [[ "$addresses" == *" 192.168.31.172 "* ]]; then
        print -r -- "$LLAMA_MODEL_172"
    else
        print -r -- "$LLAMA_MODEL_LOCAL"
    fi
}

function llama_update() {
    cd "$LLAMA" || return 1
    echo "📥 Pulling latest llama.cpp changes..."
    git pull
    # Detect GPU count
    local gpu_count
    gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    local build_dir="build"
    if [[ "$gpu_count" -gt 1 ]]; then
        build_dir="duplet_build"
        echo "🔧 Detected $gpu_count GPUs - building in $build_dir/ for multi-GPU optimization..."
    else
        echo "🔧 Detected $gpu_count GPU - building in $build_dir/"
    fi
    echo "🔧 Configuring CMake with CUDA support..."
    local -a cmake_args=(
        -B "$build_dir"
        -DGGML_CUDA=ON
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_SHARED_LIBS=OFF
        -DLLAMA_OPENSSL=ON
    )

    # The A5000 hosts provide this toolkit explicitly; the RTX 3060 host
    # relies on CMake's CUDA discovery instead.
    if [[ -x /usr/local/cuda-12.8/bin/nvcc ]]; then
        cmake_args+=(
            -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.8/bin/nvcc
            -DCMAKE_CUDA_ARCHITECTURES=86
        )
    fi

    cmake "${cmake_args[@]}"
    echo "🏗️ Building llama.cpp using $(nproc) parallel jobs..."
    cmake --build "$build_dir" --config Release -j "$(nproc)"
    echo "✅ Build complete! Binary location: $LLAMA/${build_dir}/bin/"
}

function qwen_server() {
    local default_ctx_size=131072
    local large_ctx_size=262144
    local large_ctx_vram_mib=45000
    local default_temp=0.7
    local default_top_p=0.80
    local default_presence_penalty=1.5
    local think_temp=1.0
    local think_top_p=0.95
    local think_presence_penalty=0.0

    local has_think=false
    local mtp_mode=false
    local dry_run=false
    local mmproj_path=""
    local model_path=$(_qwen_default_model)
    local model_name="qwen"
    local ctx_size=$default_ctx_size
    local ctx_size_set=false
    local parallel=1
    local temp=$default_temp
    local top_k=20
    local top_p=$default_top_p
    local min_p=0.0
    local presence_penalty=$default_presence_penalty
    local repeat_penalty=1.0
    local quantized_kv=true
    local api_key="$LLAMA_API_KEY"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --think)
                has_think=true
                shift
                ;;
            --mtp)
                mtp_mode=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --mmproj)
                [[ $# -ge 2 ]] || {
                    echo "❌ --mmproj requires a path"
                    return 1
                }
                mmproj_path="$2"
                shift 2
                ;;
            --model)
                [[ $# -ge 2 ]] || {
                    echo "❌ --model requires a path"
                    return 1
                }
                model_path="$2"
                shift 2
                ;;
            --ctx-size)
                [[ $# -ge 2 && "$2" == <-> && "$2" -gt 0 ]] || {
                    echo "❌ --ctx-size requires a positive integer"
                    return 1
                }
                ctx_size="$2"
                ctx_size_set=true
                shift 2
                ;;
            --parallel)
                [[ $# -ge 2 && "$2" == <-> && "$2" -gt 0 ]] || {
                    echo "❌ --parallel requires a positive integer"
                    return 1
                }
                parallel="$2"
                shift 2
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo "Usage: qwen_server [--model /path/to/model.gguf] [--think | --mtp] [--mmproj /path/to/mmproj.gguf] [--ctx-size N] [--parallel N] [--dry-run]"
                return 1
                ;;
        esac
    done

    # Validate incompatible modes
    if [[ "$has_think" == true && "$mtp_mode" == true ]]; then
        echo "❌ --think and --mtp cannot be used together"
        return 1
    fi

    if [[ ! -f "$model_path" ]]; then
        echo "❌ Model not found: $model_path"
        echo "   Override it with: qwen_server --model /path/to/model.gguf"
        return 1
    fi

    local gpu_count total_vram_mib
    gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    total_vram_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null |
        awk '{ gsub(/ /, "", $0); total += $0 } END { print total + 0 }')

    if [[ "$ctx_size_set" != true ]]; then
        if [[ "$gpu_count" -gt 1 && "$total_vram_mib" -ge "$large_ctx_vram_mib" ]]; then
            ctx_size=$large_ctx_size
        fi
    fi


    model_name=$(basename "$model_path" .gguf)
    if [[ "$has_think" == true ]]; then
        temp=$think_temp
        top_p=$think_top_p
        presence_penalty=$think_presence_penalty
    fi

    if [[ "$gpu_count" -gt 1 ]]; then
        cd "$LLAMA/duplet_build/bin" || return 1
    else
        cd "$LLAMA/build/bin" || return 1
    fi

    export LLAMA_NO_HF_MIGRATION=1

    local -a cmd=(
        ./llama-server
        --alias "$model_name"
        --model "$model_path"
        --port "$LLAMA_PORT"
        --host 0.0.0.0
        --api-key "$api_key"
        --flash-attn on
        --temp "$temp"
        --top-p "$top_p"
        --min-p "$min_p"
        --top-k "$top_k"
        --load-mode none
        --parallel "$parallel"
        --presence-penalty "$presence_penalty"
        --repeat-penalty "$repeat_penalty"
        --ctx-size "$ctx_size"
    )

    if [[ "$quantized_kv" == true ]]; then
        cmd+=(
            --cache-type-k q8_0
            --cache-type-v q8_0
        )
    fi

    if [[ -n "$mmproj_path" ]]; then
        if [[ ! -f "$mmproj_path" ]]; then
            echo "❌ mmproj not found: $mmproj_path"
            return 1
        fi

        cmd+=(--mmproj "$mmproj_path")
    fi

    if [[ "$has_think" == true ]]; then
        cmd+=(
            --reasoning on
            --reasoning-preserve
        )
    elif [[ "$mtp_mode" == true ]]; then
        cmd+=(
            --spec-type draft-mtp
            --spec-draft-n-max 2
            --reasoning off
        )
    else
        cmd+=(--reasoning off)
    fi

    echo "🚀 Starting Qwen server with:"
    echo "   Model:       $model_path"
    echo "   Alias:       $model_name"
    echo "   Context:     $ctx_size"
    echo "   Parallel:    $parallel"
    echo "   Temperature: $temp"
    echo "   Top P:       $top_p"
    echo "   Min P:       $min_p"
    echo "   Top K:       $top_k"
    echo "   Presence:    $presence_penalty"
    echo "   Repeat:      $repeat_penalty"
    echo "   Q8 KV cache: $quantized_kv"
    echo "   Think:       $has_think"
    echo "   MTP:         $mtp_mode"
    echo "   GPUs:        $gpu_count"
    echo "   Total VRAM:  ${total_vram_mib} MiB"

    if [[ -n "$mmproj_path" ]]; then
        echo "   mmproj:      $mmproj_path"
    fi

    if [[ "$dry_run" == true ]]; then
        print -r -- "   Command:      ${(q+)cmd}"
        return 0
    fi

    sudo ufw allow "$LLAMA_PORT/tcp"

    # Ensure the temporary firewall rule is removed on exit or interruption.
    trap 'sudo ufw delete allow "$LLAMA_PORT/tcp" >/dev/null 2>&1' EXIT INT TERM

    "${cmd[@]}"
    local exit_code=$?

    trap - EXIT INT TERM
    sudo ufw delete allow "$LLAMA_PORT/tcp"

    return "$exit_code"
}
