# MUST use the 'devel' tag to get the nvcc compiler.
FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-devel

# --- CRITICAL BUILD CONFIG ---
# 1. Force specific GPU architectures to avoid detection errors during build
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0+PTX"

# 2. Force CUDA paths
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# 3. Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1

# --- INSTALLATION ---
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    g++ \
    libsndfile1 \
    ffmpeg \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Clone the specific Qwen3-Omni fork
RUN git clone -b qwen3_omni https://github.com/wangxiongts/vllm.git

WORKDIR /workspace/vllm

# Install build requirements
RUN pip install --upgrade pip && \
    pip install -r requirements/build.txt

# Install vLLM from source
# MAX_JOBS=96 is very high. Unless you have a Threadripper/EPYC CPU,
# lower this to (Total Cores - 2) to prevent OOM crashes.
ENV MAX_JOBS=96
RUN pip install . --no-build-isolation

# Install Qwen3-Omni specific dependencies
RUN pip install git+https://github.com/huggingface/transformers && \
    pip install accelerate && \
    pip install qwen-omni-utils -U && \
    pip install flash-attn --no-build-isolation

WORKDIR /workspace

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
