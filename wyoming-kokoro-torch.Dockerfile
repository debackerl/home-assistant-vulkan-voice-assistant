FROM almalinux:10-minimal

RUN microdnf -y install python3 python3-pip espeak-ng && \
    pip install 'torch==2.8.*' --index-url https://download.pytorch.org/whl/cpu && \
    pip install 'wyoming-kokoro-torch==3.0.0.post1' misaki[en] && \
    pip install 'https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl' && \
    microdnf clean all && \
    rm -rf /var/cache/dnf /root/.cache

RUN mkdir /app
WORKDIR /app

CMD ["/usr/local/bin/wyoming-kokoro-torch"]
