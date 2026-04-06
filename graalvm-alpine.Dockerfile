# Stage 1: Build the native image with GraalVM
FROM ghcr.io/graalvm/native-image-community:21-ol9 AS builder

WORKDIR /build

# Install Maven
RUN microdnf install -y maven && microdnf clean all

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the native image
COPY sample-app/src ./src
RUN mvn -Pnative clean package -DskipTests -B native:compile

# Stage 2: Create the final image with Alpine (debug-friendly)
FROM docker.io/alpine:3.21

# Install glibc compatibility layer and essential tools
RUN apk add --no-cache \
        ca-certificates \
        tzdata \
        gcompat \
        libstdc++ && \
    addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

WORKDIR /app

# Copy the native binary
COPY --from=builder /build/target/demo /app/application

RUN chmod +x /app/application && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

# Health check (Alpine has wget available)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["/app/application"]
