# JVM Tuning for Containers

This guide covers essential JVM flags and tuning strategies for running Java applications inside Docker containers.

## Container-Aware JVM Settings

Modern JVMs (Java 10+) are container-aware by default. These flags fine-tune that behavior:

| Flag | Description | Recommended Value |
|------|-------------|-------------------|
| `-XX:+UseContainerSupport` | Enables container resource detection | Enabled by default since JDK 10 |
| `-XX:MaxRAMPercentage=75.0` | Max heap as percentage of container memory | 75% (leaves room for metaspace, threads, native memory) |
| `-XX:InitialRAMPercentage=50.0` | Initial heap as percentage of container memory | 50% (avoids aggressive early GC) |
| `-XX:MinRAMPercentage=25.0` | Min heap percentage (applies when total memory < 256MB) | 25% |

### Why 75% and not higher?

The JVM needs memory beyond the heap:
- **Metaspace**: Class metadata (~50-100MB for Spring Boot)
- **Thread stacks**: ~1MB per thread (default)
- **Code cache**: JIT-compiled code (~50-240MB)
- **Direct buffers**: NIO operations
- **Native memory**: JNI, GC overhead

Setting `MaxRAMPercentage` above 80% risks OOM kills from the container runtime.

## Garbage Collector Selection

### G1GC (Default since JDK 9) - Recommended for most workloads

```
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+UseStringDeduplication
```

Best for: General-purpose, heap sizes > 512MB, latency-sensitive applications.

### ZGC - Low latency

```
-XX:+UseZGC
-XX:+ZGenerational
```

Best for: Large heaps (multi-GB), sub-millisecond pause requirements. Available since JDK 21 as production-ready.

### Serial GC - Small containers

```
-XX:+UseSerialGC
```

Best for: Containers with < 256MB RAM or single-core allocation.

## Startup Optimization

### Class Data Sharing (CDS / AppCDS)

CDS shares class metadata across JVM instances and speeds up startup by 10-30%:

```dockerfile
# Generate CDS archive during build
RUN java -Xshare:dump -XX:SharedArchiveFile=/app/classes.jsa -jar /app/app.jar --dry-run || true

# Use CDS at runtime
ENTRYPOINT ["java", "-Xshare:on", "-XX:SharedArchiveFile=/app/classes.jsa", "-jar", "/app/app.jar"]
```

### Spring Boot Specific

```
-Dspring.jmx.enabled=false
-Dspring.config.location=classpath:/application.properties
```

Disabling JMX saves ~10MB of memory and reduces startup time.

## Security

```
-Djava.security.egd=file:/dev/./urandom
```

Uses non-blocking entropy source. This avoids startup delays on systems with low entropy (common in containers).

## Complete Production Example

```
java \
  -XX:+UseContainerSupport \
  -XX:MaxRAMPercentage=75.0 \
  -XX:InitialRAMPercentage=50.0 \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UseStringDeduplication \
  -Djava.security.egd=file:/dev/./urandom \
  -jar /app/app.jar
```

## Memory Sizing Guide

| Container Memory Limit | MaxRAMPercentage | Effective Max Heap | Good For |
|------------------------|------------------|--------------------|----------|
| 256MB | 50% | ~128MB | Lightweight microservices |
| 512MB | 75% | ~384MB | Small APIs |
| 1GB | 75% | ~768MB | Standard microservices |
| 2GB | 75% | ~1.5GB | Medium workloads |
| 4GB+ | 75% | ~3GB+ | Heavy processing |

## Kubernetes Resource Limits

Always set container memory limits. Without them, `MaxRAMPercentage` uses the host's total RAM:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "1000m"
```

## References

- [Eclipse Temurin Container Support](https://adoptium.net/)
- [JDK 21 GC Tuning Guide](https://docs.oracle.com/en/java/javase/21/gctuning/)
- [Spring Boot Docker Guide](https://spring.io/guides/topicals/spring-boot-docker)
