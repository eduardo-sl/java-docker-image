# Optimized Java Docker Images

This repository offers highly optimized Docker images for Java applications using multi-stage builds, minimal base images, and JVM tuning best practices. It includes both traditional JVM-based images and GraalVM Native Image variants for maximum performance.

A single [Spring Boot sample application](sample-app/) is used across all Dockerfile flavors, making it easy to compare image sizes, startup times, and memory usage.

## Image Size Comparison

### JVM-Based Images

| Dockerfile | Base Image | Approx. Size | Use Case |
|------------|-----------|--------------|----------|
| `distroless.Dockerfile` | Distroless Java 21 | ~200MB | Production (maximum security) |
| `alpine.Dockerfile` | Eclipse Temurin 21 JRE Alpine | ~180MB | Production (balanced, debug-friendly) |
| `jlink.Dockerfile` | Alpine + Custom JRE | ~100-150MB | Production (smallest JVM image) |

### GraalVM Native Image

| Dockerfile | Base Image | Approx. Size | Use Case |
|------------|-----------|--------------|----------|
| `graalvm-distroless.Dockerfile` | Distroless static | ~25-40MB | Production (recommended native) |
| `graalvm-scratch.Dockerfile` | scratch | ~30-50MB | Minimal (no OS) |
| `graalvm-alpine.Dockerfile` | Alpine | ~40-60MB | Debug-friendly native |
| `graalvm-upx.Dockerfile` | scratch + UPX | ~15-25MB | Smallest possible image |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with BuildKit enabled)
- For GraalVM images: at least 4GB of RAM available for Docker

## Building and Running the Images

### Distroless (Recommended for Production)

Uses `gcr.io/distroless/java21-debian12` - a minimal image with no shell, package manager, or unnecessary libraries. Ideal for production environments with strict security requirements.

```bash
docker build -t myapp-distroless -f distroless.Dockerfile .
docker run -p 8080:8080 myapp-distroless
```

### Alpine JRE (Balanced)

Uses `eclipse-temurin:21-jre-alpine` - small image with shell access for debugging, health checks, and timezone support.

```bash
docker build -t myapp-alpine -f alpine.Dockerfile .
docker run -p 8080:8080 myapp-alpine
```

### JLink Custom JRE (Smallest JVM)

Creates a custom JRE with only the modules your application needs using `jlink`. Three-stage build: compile, create custom JRE, assemble final image.

```bash
docker build -t myapp-jlink -f jlink.Dockerfile .
docker run -p 8080:8080 myapp-jlink
```

### GraalVM Distroless (Recommended Native)

Compiles the application to a native binary using GraalVM and runs it on a Distroless static image. Near-instant startup and minimal memory footprint.

```bash
docker build -t myapp-graalvm-distroless -f graalvm-distroless.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-distroless
```

### GraalVM Scratch (Ultra Minimal)

Static native binary on an empty base image. The smallest possible image containing only your binary, CA certificates, and timezone data.

```bash
docker build -t myapp-graalvm-scratch -f graalvm-scratch.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-scratch
```

### GraalVM Alpine (Debug-Friendly Native)

Native binary on Alpine Linux. Includes a shell for debugging and troubleshooting.

```bash
docker build -t myapp-graalvm-alpine -f graalvm-alpine.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-alpine
```

### GraalVM UPX (Smallest Possible)

Static native binary compressed with UPX for extreme size reduction (50-70% smaller). Best for edge computing and serverless.

```bash
docker build -t myapp-graalvm-upx -f graalvm-upx.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-upx
```

## Testing the Application

After running any image, test the endpoints:

```bash
# Hello endpoint
curl http://localhost:8080/

# JVM and runtime info
curl http://localhost:8080/info

# Health check (Spring Boot Actuator)
curl http://localhost:8080/actuator/health
```

## Building Multi-Platform Docker Images

Use Docker Buildx to build images for multiple architectures:

1. Create and bootstrap a new builder:
    ```bash
    docker buildx create --use --name javabuilder --driver docker-container
    docker buildx inspect javabuilder --bootstrap
    ```

2. Build for a specific platform:
    ```bash
    # AMD64
    docker buildx build --platform linux/amd64 -t myapp-distroless-amd64 -f distroless.Dockerfile --load .

    # ARM64
    docker buildx build --platform linux/arm64 -t myapp-distroless-arm64 -f distroless.Dockerfile --load .
    ```

3. Build and push for multiple platforms:
    ```bash
    docker buildx build --platform linux/amd64,linux/arm64 \
      -t myuser/myapp:latest -f distroless.Dockerfile --push .
    ```

## JVM Tuning for Containers

All JVM-based Dockerfiles include optimized flags:

```
-XX:+UseContainerSupport          # Detect container memory/CPU limits
-XX:MaxRAMPercentage=75.0         # Use 75% of container RAM for heap
-XX:+UseG1GC                      # G1 Garbage Collector (balanced throughput/latency)
-XX:+UseStringDeduplication        # Deduplicate strings in the heap
-Djava.security.egd=file:/dev/./urandom  # Non-blocking entropy source
```

See [docs/JVM_TUNING.md](docs/JVM_TUNING.md) for a complete guide on memory configuration, GC selection, and CDS.

## Security Features

- **Non-root execution**: All images run as non-root users
- **Minimal attack surface**: No shell or package manager in Distroless/Scratch images
- **Pinned base images**: Specific JDK/JRE versions for reproducible builds
- **CA certificates**: Included for HTTPS support
- **Layer caching**: Dependencies are cached separately from source code

See [docs/SECURITY.md](docs/SECURITY.md) for detailed security best practices.

## Which Dockerfile Should I Use?

| Scenario | Recommended Dockerfile |
|----------|------------------------|
| Production with maximum security | `distroless.Dockerfile` |
| Need shell access for debugging | `alpine.Dockerfile` |
| Smallest JVM-based image | `jlink.Dockerfile` |
| Fastest startup / lowest memory | `graalvm-distroless.Dockerfile` |
| Absolute smallest image | `graalvm-upx.Dockerfile` |
| Native image + debugging | `graalvm-alpine.Dockerfile` |
| Serverless / AWS Lambda | `graalvm-scratch.Dockerfile` |

## Documentation

- [JVM Tuning for Containers](docs/JVM_TUNING.md) - Memory configuration, GC selection, CDS, Kubernetes resource limits
- [GraalVM Native Image Guide](docs/GRAALVM_NATIVE.md) - AOT compilation, static binaries, limitations
- [Docker Security Best Practices](docs/SECURITY.md) - Non-root, image scanning, secrets management

## Additional Resources

- [Google Distroless](https://github.com/GoogleContainerTools/distroless)
- [Eclipse Temurin](https://adoptium.net/)
- [GraalVM](https://www.graalvm.org/)
- [Spring Boot Docker Guide](https://spring.io/guides/topicals/spring-boot-docker)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [JLink Documentation](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jlink.html)
