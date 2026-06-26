# EVO LLM STUFF
#
export PATH="$PATH:$HOME/repos/llama.cpp/build/bin"
export OPENAI_API_KEY="sk-no-key-required"
export OPENAI_BASE_URL="http://localhost:8080/v1"

function llama_update() {
    cd $HOME/repos/llama.cpp/
    echo "📥 Pulling latest llama.cpp changes..."
    git pull
    if [[ $1 == "--mtp" ]]; then
        echo "🔧 Building with MTP support..."
        cmake -B build -DBUILD_SHARED_LIBS=OFF -DGGML_CUDA=ON
        cmake --build build --config Release -j $(nproc) --clean-first \
              --target llama-cli llama-mtmd-cli llama-server llama-gguf-split
    else
        echo "🔧 Building standard version..."
        cmake -B build -DGGML_CUDA=ON -DLLAMA_CURL=ON -DCMAKE_BUILD_TYPE=Release
        cmake --build build --config Release -j $(nproc)
    fi
}

function qwen_server() {
    local has_think=false

    for arg in "$@"; do
        case $arg in
            --think) has_think=true ;;
            --mmproj) mmproj_path="/home/rpamirov/models/qwen3.6-35b/mmproj-F16.gguf";;
        esac
    done

    cd $HOME/repos/llama.cpp/build/bin/
    export LLAMA_NO_HF_MIGRATION=1

    local -a cmd=(
        ./llama-server
        --alias "Qwen3.6-35B-A3B-UD-Q3_K_XL"
        --model $HOME/models/qwen3.6-35b/Qwen3.6-35B-A3B-UD-Q3_K_XL.gguf
        --port 8080
        --host 0.0.0.0
        --flash-attn on
        --min-p 0.0
        --temp 0.6
        --top-p 0.95
        --top-k 20
        --no-mmap
        --presence-penalty 1.5
        --repeat-penalty 1.0
        --ctx-size 120000
    )

    if [[ $has_think == true ]]; then
        cmd+=(--reasoning on)
    else
        cmd+=(--reasoning off)
    fi

    if [[ -n $mmproj_path ]]; then
        cmd+=(--mmproj $mmproj_path)
    fi
    "${cmd[@]}"
}
