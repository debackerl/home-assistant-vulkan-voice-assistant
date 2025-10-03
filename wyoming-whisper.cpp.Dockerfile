FROM almalinux:10-minimal AS builder
RUN microdnf -y install vulkan-loader-devel glslc git gcc-c++ cmake python3-pip python3-devel

ENV GGML_VULKAN=1
RUN pip install git+https://github.com/absadiki/pywhispercpp@v1.3.3 'wyoming-whisper.cpp==2.6.1'


FROM almalinux:10-minimal

RUN microdnf -y install mesa-vulkan-drivers libgomp python3 && \
    rpm -i https://github.com/GPUOpen-Drivers/AMDVLK/releases/download/v-2025.Q2.1/amdvlk-2025.Q2.1.x86_64.rpm && \
    microdnf clean all && \
    rm -rf /var/cache/dnf

RUN mkdir /app
WORKDIR /app

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/lib64/python3.12/site-packages /usr/local/lib64/python3.12/site-packages
COPY --from=builder /usr/local/bin/wyoming-whisper-cpp /usr/local/bin/

CMD ["/usr/local/bin/wyoming-whisper-cpp"]
