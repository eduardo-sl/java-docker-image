# Optimized Java Docker Images

This repository offers highly optimized Docker images for Java applications using multi-stage builds, minimal base images, and JVM tuning best practices. It includes both traditional JVM-based images and GraalVM Native Image variants for maximum performance.

A single [Spring Boot sample application](sample-app/) is used across all Dockerfile flavors, making it easy to compare image sizes, startup times, and memory usage.

## Image Size Comparison

### JVM-Based Images

| Dockerfile | Base Image | Approx. Size | Use Case |
|------------|-----------|--------------|----------|
| `distroless.Dockerfile` | Distroless Java 25 | ~200MB | Production (maximum security) |
| `alpine.Dockerfile` | Eclipse Temurin 25 JRE Alpine | ~180MB | Production (balanced, debug-friendly) |
| `jlink.Dockerfile` | Alpine + Custom JRE | ~100-150MB | Production (smallest JVM image) |

### GraalVM Native Image

| Dockerfile | Base Image | Approx. Size | Use Case |
|------------|-----------|--------------|----------|
| `graalvm-distroless.Dockerfile` | Distroless cc Debian 13 | ~25-40MB | Production (recommended native) |
| `graalvm-scratch.Dockerfile` | scratch + copied glibc runtime | ~30-50MB | Minimal runtime, no package manager |
| `graalvm-alpine.Dockerfile` | Alpine | ~40-60MB | Debug-friendly native |
| `graalvm-upx.Dockerfile` | Distroless cc Debian 13 + UPX | ~15-25MB | Smallest practical native image |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with BuildKit enabled)
- For GraalVM images: at least 4GB of RAM available for Docker

## Building and Running the Images

### Distroless (Recommended for Production)

Uses `gcr.io/distroless/java25-debian13` - a minimal image with no shell, package manager, or unnecessary libraries. Ideal for production environments with strict security requirements.

```bash
docker build -t myapp-distroless -f distroless.Dockerfile .
docker run -p 8080:8080 myapp-distroless
```

### Alpine JRE (Balanced)

Uses `eclipse-temurin:25-jre-alpine` - small image with shell access for debugging, health checks, and timezone support.

```bash
docker build -t myapp-alpine -f alpine.Dockerfile .
docker run -p 8080:8080 myapp-alpine
```

### JLink Custom JRE (Smallest JVM)

Creates a custom JRE with `jlink`. For this Spring Boot executable jar, the runtime starts from `java.se` and adds only the extra JDK modules needed by the app, which is more reliable than trusting `jdeps` output alone. Three-stage build: compile, create custom JRE, assemble final image.

```bash
docker build -t myapp-jlink -f jlink.Dockerfile .
docker run -p 8080:8080 myapp-jlink
```

### GraalVM Distroless (Recommended Native)

Compiles the application to a native binary using GraalVM and runs it on `gcr.io/distroless/cc-debian13:nonroot`. Near-instant startup and minimal memory footprint.

```bash
docker build -t myapp-graalvm-distroless -f graalvm-distroless.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-distroless
```

### GraalVM Scratch (Minimal Runtime)

Native binary on `scratch` with the minimum glibc runtime files copied from the builder. This keeps the image extremely small while avoiding the `musl` toolchain issues seen with current GraalVM community `muslib` images in this environment.

```bash
docker build -t myapp-graalvm-scratch -f graalvm-scratch.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-scratch
```

If you need the most operationally stable native image, prefer `graalvm-distroless.Dockerfile`. If you specifically need a fully static `musl` binary, be aware that the tested `25-muslib-ol8`, `25-muslib-ol9`, and `25-muslib-ol10` builders failed during `native-image` in this environment, so the scratch variant here is intentionally glibc-based.

### GraalVM Alpine (Debug-Friendly Native)

Native binary on Alpine Linux. Includes a shell for debugging and troubleshooting.

```bash
docker build -t myapp-graalvm-alpine -f graalvm-alpine.Dockerfile .
docker run -p 8080:8080 myapp-graalvm-alpine
```

### GraalVM UPX (Smallest Possible)

Native binary compressed with UPX for extreme size reduction (often 50-70% smaller) and run on Distroless `cc`. Best when image size matters more than build simplicity.

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
-XX:+UseContainerSupport           # Detect container memory/CPU limits
-XX:MaxRAMPercentage=75.0          # Use 75% of container RAM for heap
-XX:+UseG1GC                       # G1 Garbage Collector (balanced throughput/latency)
-XX:+UseStringDeduplication        # Deduplicate strings in the heap
-XX:+ExitOnOutOfMemoryError        # Exit immediately on OOM (lets orchestrator restart)
-Djava.security.egd=file:/dev/./urandom  # Non-blocking entropy source
```

See [docs/JVM_TUNING.md](docs/JVM_TUNING.md) for a complete guide on memory configuration, GC selection, and CDS.

## Security Features

- **Non-root execution**: All images run as non-root users
- **Minimal attack surface**: No shell or package manager in Distroless/Scratch images
- **Versioned base images**: Java 25 and Debian 13 image families keep the examples aligned on a current runtime baseline
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
- [JLink Documentation](https://docs.oracle.com/en/java/javase/25/docs/specs/man/jlink.html)
