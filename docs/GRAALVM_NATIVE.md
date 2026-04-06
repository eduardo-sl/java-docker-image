# GraalVM Native Image Guide

GraalVM Native Image compiles Java applications ahead-of-time (AOT) into standalone native executables. The result is dramatically smaller images, near-instant startup, and lower memory footprint.

## Why Native Image?

| Metric | JVM (OpenJDK) | GraalVM Native |
|--------|---------------|----------------|
| Docker image size | ~180-200MB | ~25-80MB |
| Startup time | 3-5 seconds | 30-80ms |
| RAM usage | 150-300MB | 50-100MB |
| Build time | 30-60s | 3-10min |

## Dockerfiles in This Repository

| Dockerfile | Base Image | Size | Use Case |
|------------|-----------|------|----------|
| `graalvm-distroless` | Distroless `cc-debian13` | ~25-40MB | Production (recommended) |
| `graalvm-scratch` | `scratch` + copied glibc runtime | ~30-50MB | Minimal runtime, no package manager |
| `graalvm-alpine` | Alpine | ~40-60MB | Debug-friendly |
| `graalvm-upx` | Distroless `cc-debian13` + UPX | ~15-25MB | Smallest practical image |

## Spring Boot 3.x Native Support

Spring Boot 3.x has first-class GraalVM native image support via the `native` Maven profile:

```xml
<profiles>
    <profile>
        <id>native</id>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.graalvm.buildtools</groupId>
                    <artifactId>native-maven-plugin</artifactId>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

Build with: `mvn -Pnative clean package -DskipTests native:compile`

## Static vs Dynamic Binaries

- **Dynamic binary** (default): Requires glibc at runtime. Use with Alpine + gcompat or Distroless.
- **Static binary** (`--static --libc=musl`): No runtime dependencies. Use with scratch or Distroless static.

Static binaries are larger but completely self-contained.

In this repository, the native images are currently built as dynamic glibc binaries. The `scratch` variant works by copying the minimal runtime linker and shared libraries from the builder stage. This choice is deliberate because the tested GraalVM Community `muslib` builders for Java 25 were not stable in this environment.

## UPX Compression

[UPX](https://upx.github.io/) compresses native binaries by 50-70%:

```bash
upx --best --lzma target/demo
```

Trade-off: Slightly slower startup (decompression overhead of ~50-100ms).

## Limitations

1. **Reflection**: Must be configured at build time via hints or `reflect-config.json`
2. **Dynamic class loading**: Not supported
3. **JNI**: Requires explicit configuration
4. **Build time**: 3-10x slower than standard JVM builds
5. **Peak throughput**: May be lower than JIT-compiled JVM for long-running processes

## When to Use Native Image

**Ideal for:**
- Microservices with variable traffic
- Serverless / AWS Lambda / Azure Functions
- CLI tools
- Kubernetes with autoscaling (fast scale-up)
- Edge computing

**Consider JVM instead when:**
- Peak throughput matters more than startup
- Application relies heavily on reflection
- Build time is critical (CI/CD pipelines)
- Large monolithic applications

## Repository-Specific Guidance

- Prefer `graalvm-distroless.Dockerfile` for production: smallest operational risk with a minimal runtime.
- Prefer `graalvm-scratch.Dockerfile` when you want a tiny image and accept a more manual runtime layout.
- Prefer `graalvm-upx.Dockerfile` only when the extra compression step is worth the slower build and potential operational complexity.

## References

- [GraalVM Official](https://www.graalvm.org/)
- [Spring Boot Native Image](https://docs.spring.io/spring-boot/reference/native-image/)
- [Native Build Tools](https://graalvm.github.io/native-build-tools/)
