FROM golang:1.25 AS build

WORKDIR /go/src/app

RUN git clone --depth 1 https://github.com/debackerl/ollama-proxy.git .

RUN go mod download
RUN CGO_ENABLED=0 go build -o /go/bin/ollama-proxy


FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/ollama-proxy /bin/

CMD ["/bin/ollama-proxy"]
