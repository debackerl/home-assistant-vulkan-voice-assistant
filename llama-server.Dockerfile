FROM almalinux:10-minimal AS builder
RUN microdnf -y install vulkan-loader-devel glslc git gcc-c++ cmake libcurl-devel

RUN git clone --depth 1 --branch b6432 https://github.com/ggml-org/llama.cpp.git

RUN cmake llama.cpp -B llama.cpp/build -D GGML_VULKAN=ON -DLLAMA_BUILD_TESTS=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON && \
    cmake --build llama.cpp/build --config Release -j --target llama-bench llama-cli llama-server llama-gguf


FROM almalinux:10-minimal

RUN microdnf -y install mesa-vulkan-drivers libgomp && \
    rpm -i https://github.com/GPUOpen-Drivers/AMDVLK/releases/download/v-2025.Q2.1/amdvlk-2025.Q2.1.x86_64.rpm && \
    microdnf clean all && \
    rm -rf /var/cache/dnf

RUN mkdir /app
WORKDIR /app

COPY --from=builder /llama.cpp/build/bin/llama-bench /llama.cpp/build/bin/llama-cli /llama.cpp/build/bin/llama-server /llama.cpp/build/bin/llama-gguf /llama.cpp/build/bin/*.so .

ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080
ENV LLAMA_ARG_CTX_SIZE=8192
ENV LLAMA_ARG_N_GPU_LAYERS=999
ENV LLAMA_ARG_NO_MMAP=1

CMD ["/app/llama-server"]
