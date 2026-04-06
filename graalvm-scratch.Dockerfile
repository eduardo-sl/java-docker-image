# Stage 1: Build the native image with GraalVM (static binary with musl)
FROM ghcr.io/graalvm/native-image-community:21-muslib-ol9 AS builder

WORKDIR /build

# Install Maven
RUN microdnf install -y maven && microdnf clean all

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build a fully static native image
COPY sample-app/src ./src
RUN mvn -Pnative clean package -DskipTests -B native:compile \
    -Dnative.build.args="--static --libc=musl"

# Stage 2: Create the final image from scratch (empty image)
FROM scratch

WORKDIR /app

# Copy the static native binary
COPY --from=builder /build/target/demo /app/application

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
