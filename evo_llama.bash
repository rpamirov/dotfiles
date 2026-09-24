# Bash configuration and helpers for the local llama.cpp Qwen server.

: "${LLAMA_MODELS_DIR:=/DATA/SQA/LLM/models}"
: "${LLAMA_API_KEY:=sk-no-key-required}"
export LLAMA_MODELS_DIR LLAMA_API_KEY
export LLAMA_PORT="${LLAMA_PORT:-9931}"
export LLAMA_BASE_URL="http://localhost:${LLAMA_PORT}/v1"

LLAMA_MODEL_171="$LLAMA_MODELS_DIR/Qwen3.8-27B-UD-Q4_K_M.gguf"
LLAMA_MODEL_172="$LLAMA_MODELS_DIR/Qwen3.8-27B-UD-Q6_K.gguf"
LLAMA_MODEL_LOCAL="$LLAMA_MODELS_DIR/Qwen3.6-35B-A3B-UD-IQ4_NL.gguf"

_qwen_default_model() {
    local addresses
    addresses=" $(hostname -I 2>/dev/null) "
    case "$addresses" in
        *" 192.168.31.171 "*) printf '%s\n' "$LLAMA_MODEL_171" ;;
        *" 192.168.31.172 "*) printf '%s\n' "$LLAMA_MODEL_172" ;;
        *) printf '%s\n' "$LLAMA_MODEL_LOCAL" ;;
    esac
}

llama_update() {
    cd "${LLAMA:?LLAMA must point to the llama.cpp checkout}" || return 1
    echo "Pulling latest llama.cpp changes..."
    git pull || return 1

    local gpu_count build_dir
    gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    build_dir=build
    (( gpu_count > 1 )) && build_dir=duplet_build

    local -a cmake_args=(
        -B "$build_dir" -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
        -DBUILD_SHARED_LIBS=OFF -DLLAMA_OPENSSL=ON
    )
    if [[ -x /usr/local/cuda-12.8/bin/nvcc ]]; then
        cmake_args+=(
            -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.8/bin/nvcc
            -DCMAKE_CUDA_ARCHITECTURES=86
        )
    fi
    cmake "${cmake_args[@]}" || return 1
    cmake --build "$build_dir" --config Release -j "$(nproc)"
}

qwen_server() {
    local reasoning_mode=on mtp_mode=false dry_run=false
    local mmproj_path='' model_path model_name ctx_size=131072
    local ctx_size_set=false parallel=1 temp=0.7 top_k=20 top_p=0.80 min_p=0.0
    local presence_penalty=1.5 repeat_penalty=1.0 quantized_kv=true
    local gpu_count total_vram_mib build_dir
    model_path=$(_qwen_default_model)

    while (($#)); do
        case "$1" in
            --reasoning)
                [[ ${2:-} == on || ${2:-} == off || ${2:-} == auto ]] || { echo "--reasoning requires on, off, or auto" >&2; return 1; }
                reasoning_mode=$2; shift 2 ;;
            --mtp) mtp_mode=true; shift ;;
            --dry-run) dry_run=true; shift ;;
            --mmproj|--model|--ctx-size|--parallel)
                [[ $# -ge 2 ]] || { echo "$1 requires a value" >&2; return 1; }
                case "$1" in
                    --mmproj) mmproj_path=$2 ;;
                    --model) model_path=$2 ;;
                    --ctx-size) [[ $2 =~ ^[1-9][0-9]*$ ]] || { echo "--ctx-size requires a positive integer" >&2; return 1; }; ctx_size=$2; ctx_size_set=true ;;
                    --parallel) [[ $2 =~ ^[1-9][0-9]*$ ]] || { echo "--parallel requires a positive integer" >&2; return 1; }; parallel=$2 ;;
                esac
                shift 2 ;;
            *) echo "Usage: qwen_server [--model PATH] [--reasoning on|off|auto] [--mtp] [--mmproj PATH] [--ctx-size N] [--parallel N] [--dry-run]" >&2; return 1 ;;
        esac
    done

    [[ -f $model_path ]] || { echo "Model not found: $model_path" >&2; return 1; }
    [[ -z $mmproj_path || -f $mmproj_path ]] || { echo "mmproj not found: $mmproj_path" >&2; return 1; }

    gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    total_vram_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | awk '{ total += $1 } END { print total + 0 }')
    if ! $ctx_size_set && (( gpu_count > 1 )) && (( total_vram_mib >= 45000 )); then ctx_size=262144; fi
    [[ $reasoning_mode == on ]] && { temp=1.0; top_p=0.95; presence_penalty=0.0; }

    (( gpu_count > 1 )) && build_dir=duplet_build || build_dir=build
    cd "${LLAMA:?LLAMA must point to the llama.cpp checkout}/$build_dir/bin" || return 1
    model_name=${model_path##*/}; model_name=${model_name%.gguf}

    local -a cmd=(./llama-server --alias "$model_name" --model "$model_path" --port "$LLAMA_PORT" --host 0.0.0.0 --api-key "$LLAMA_API_KEY" --flash-attn on --temp "$temp" --top-p "$top_p" --min-p "$min_p" --top-k "$top_k" --load-mode none --fit on --ubatch-size 512 --parallel "$parallel" --presence-penalty "$presence_penalty" --repeat-penalty "$repeat_penalty" --ctx-size "$ctx_size" --cache-type-k q8_0 --cache-type-v q8_0)
    [[ -n $mmproj_path ]] && cmd+=(--mmproj "$mmproj_path")
    $mtp_mode && cmd+=(--spec-type draft-mtp --spec-draft-n-max 2)
    cmd+=(--reasoning "$reasoning_mode")
    [[ $reasoning_mode != off ]] && cmd+=(--reasoning-preserve)
    $dry_run && { printf 'Command:'; printf ' %q' "${cmd[@]}"; printf '\n'; return 0; }

    sudo ufw allow "$LLAMA_PORT/tcp" || return 1
    trap 'sudo ufw delete allow "$LLAMA_PORT/tcp" >/dev/null 2>&1' EXIT INT TERM
    "${cmd[@]}"; local status=$?
    trap - EXIT INT TERM
    sudo ufw delete allow "$LLAMA_PORT/tcp" >/dev/null 2>&1
    return "$status"
}
