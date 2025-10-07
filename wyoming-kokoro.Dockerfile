FROM almalinux:10-minimal AS builder
RUN microdnf -y install git python3-pip

WORKDIR /root

RUN git clone https://github.com/nordwestt/kokoro-wyoming.git && \
    cd kokoro-wyoming && \
    pip install -r requirements.txt && \
    pip install -r requirements-openvino.txt


FROM almalinux:10-minimal

RUN microdnf -y install python3 && \
    microdnf clean all && \
    rm -rf /var/cache/dnf

RUN mkdir /app /model
WORKDIR /model

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/lib64/python3.12/site-packages /usr/local/lib64/python3.12/site-packages
COPY --from=builder /root/kokoro-wyoming/src/main.py /app/main.py

CMD ["/usr/bin/python3", "/app/main.py"]
