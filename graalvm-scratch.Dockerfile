# Stage 1: Build a native image with GraalVM
FROM ghcr.io/graalvm/native-image-community:25-ol9 AS builder

WORKDIR /build

# Install Maven
RUN microdnf install -y maven && microdnf clean all

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the native image
COPY sample-app/src ./src
RUN mvn -Pnative clean package -DskipTests -B native:compile
RUN mkdir -p /scratch-tmp

# Stage 2: Create the final image from scratch (empty image)
FROM scratch

WORKDIR /app

# Copy the native binary and its minimal runtime dependencies
COPY --from=builder /build/target/demo /app/application
COPY --from=builder /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=builder /lib64/libc.so.6 /lib64/libc.so.6
COPY --from=builder /lib64/libz.so.1 /lib64/libz.so.1
COPY --from=builder --chown=1001:1001 /scratch-tmp /tmp

# Copy CA certificates for HTTPS support
COPY --from=builder /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Expose the application port
EXPOSE 8080

# Use a non-root user
USER 1001:1001

# Run the native application
ENTRYPOINT ["/app/application"]
