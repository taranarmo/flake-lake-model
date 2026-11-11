# Multi-stage Dockerfile for FLake Fresh-water Lake Model CLI
FROM alpine:3.20 AS builder

RUN apk add --no-cache gfortran cmake make musl-dev

WORKDIR /src
COPY . .

RUN cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j$(nproc) \
    && ctest --test-dir build --output-on-failure \
    && cmake --install build --prefix=/install

FROM alpine:3.20

RUN apk add --no-cache libgfortran

COPY --from=builder /install/bin/flake /usr/local/bin/flake
COPY examples/ /opt/flake/examples/

LABEL org.opencontainers.image.title="FLake Lake Model" \
      org.opencontainers.image.description="1D Fresh-water Lake Model Fortran CLI Runtime" \
      org.opencontainers.image.url="https://github.com/taranarmo/flake-lake-model" \
      org.opencontainers.image.source="https://github.com/taranarmo/flake-lake-model" \
      org.opencontainers.image.vendor="FLake Community" \
      org.opencontainers.image.licenses="MIT"

WORKDIR /workspace
VOLUME ["/workspace"]

ENTRYPOINT ["flake"]
CMD ["--help"]
