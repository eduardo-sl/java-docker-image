# Stage 1: Build the native image with GraalVM and compress with UPX
FROM ghcr.io/graalvm/native-image-community:21-muslib-ol9 AS builder

WORKDIR /build

# Install Maven and UPX for extreme binary compression
RUN microdnf install -y maven wget xz && \
    wget -q https://github.com/upx/upx/releases/download/v4.2.4/upx-4.2.4-amd64_linux.tar.xz && \
    tar -xf upx-4.2.4-amd64_linux.tar.xz && \
    mv upx-4.2.4-amd64_linux/upx /usr/local/bin/ && \
    rm -rf upx-* && \
    microdnf clean all

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build a fully static native image
COPY sample-app/src ./src
RUN mvn -Pnative clean package -DskipTests -B native:compile \
    -Dnative.build.args="--static --libc=musl -H:+ReportExceptionStackTraces"

# Compress the binary with UPX (reduces size by 50-70%)
RUN upx --best --lzma /build/target/demo

# Stage 2: Create the final image from scratch
FROM scratch

WORKDIR /app

# Copy the compressed static binary
COPY --from=builder /build/target/demo /app/application

# Copy CA certificates for HTTPS support
COPY --from=builder /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt

EXPOSE 8080

USER 1001:1001

ENTRYPOINT ["/app/application"]
