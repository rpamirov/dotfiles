export OPENAI_API_KEY="sk-no-key-required"
export OPENAI_BASE_URL="http://localhost:8080/v1"

function llama_update() {
    cd $LLAMA || return 1
    echo "📥 Pulling latest llama.cpp changes..."
    git pull
    # Detect GPU count
    local gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    local build_dir="build"
    if [[ "$gpu_count" -gt 1 ]]; then
        build_dir="duplet_build"
        echo "🔧 Detected $gpu_count GPUs - building in $build_dir/ for multi-GPU optimization..."
    else
        echo "🔧 Detected $gpu_count GPU - building in $build_dir/"
    fi
    echo "🔧 Configuring CMake with CUDA support..."
    cmake -B "$build_dir" \
        -DGGML_CUDA=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLAMA_CURL=ON \
        -DLLAMA_OPENSSL=ON
    echo "🏗️ Building llama.cpp using $(nproc) parallel jobs..."
    cmake --build "$build_dir" --config Release -j $(nproc)
    echo "✅ Build complete! Binary location: $LLAMA/${build_dir}bin/"
}

function qwen_server() {
    local has_think=false
    local mtp_mode=false
    local mmproj_path=""
    local model_path=""
    local model_name="qwen"
    local ctx_size=262144
    local top_p=0.95
    local min_p=0.01


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
                [[ $# -ge 2 ]] || {
                    echo "❌ --ctx-size requires a value"
                    return 1
                }
                ctx_size="$2"
                shift 2
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo "Usage: qwen_server --model /path/to/model.gguf [--think] [--mtp] [--mmproj /path/to/mmproj.gguf] [--ctx-size 262144]"
                return 1
                ;;
        esac
    done

    # Validate incompatible modes
    if [[ "$has_think" == true && "$mtp_mode" == true ]]; then
        echo "❌ --think and --mtp cannot be used together"
        return 1
    fi

    # Thinking-mode sampling parameters
    if [[ "$has_think" == true ]]; then
        temp=0.6
        top_p=0.95
        min_p=0.0
        top_k=20
    fi

    # Validate model path
    if [[ -z "$model_path" ]]; then
        echo "❌ Please specify model path: --model /path/to/model.gguf"
        return 1
    fi

    if [[ ! -f "$model_path" ]]; then
        echo "❌ Model not found: $model_path"
        return 1
    fi

    # Extract model name from path for alias
    model_name=$(basename "$model_path" .gguf)
    if [[ $model_name == "Qwen3.6-35B-A3B-UD-Q3_K_XL" ]];then
        local ctx_size=128000
        local temp=0.6
        local top_k=20
    else
        local temp=1.0
        local top_k=40
    fi


    local gpu_count
    gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)

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
        --port 8080
        --host 0.0.0.0
        --flash-attn on
        --temp "$temp"
        --top-p "$top_p"
        --min-p "$min_p"
        --top-k "$top_k"
        --no-mmap
        --parallel 1
        --presence-penalty 0.0
        --repeat-penalty 1.0
        --ctx-size "$ctx_size"
    )

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
    echo "   Temperature: $temp"
    echo "   Top P:       $top_p"
    echo "   Min P:       $min_p"
    echo "   Top K:       $top_k"
    echo "   Think:       $has_think"
    echo "   MTP:         $mtp_mode"
    echo "   GPUs:        $gpu_count"

    if [[ -n "$mmproj_path" ]]; then
        echo "   mmproj:      $mmproj_path"
    fi

    sudo ufw allow 8080/tcp

    # Ensure the temporary firewall rule is removed on exit or interruption.
    trap 'sudo ufw delete allow 8080/tcp >/dev/null 2>&1' EXIT INT TERM

    "${cmd[@]}"
    local exit_code=$?

    trap - EXIT INT TERM
    sudo ufw delete allow 8080/tcp

    return "$exit_code"
}
