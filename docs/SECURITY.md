# Docker Security Best Practices for Java

## Non-Root Execution

All Dockerfiles in this repository run as non-root users:

- **Distroless**: Uses the built-in `nonroot` user (uid 65534)
- **Alpine**: Creates a dedicated `appuser` (uid 1001)
- **Scratch**: Runs as uid 1001

Never run containers as root in production.

## Minimal Base Images

| Base Image | Shell | Package Manager | Attack Surface |
|------------|-------|-----------------|----------------|
| `scratch` | No | No | Minimal |
| `gcr.io/distroless/cc-debian13` | No | No | Minimal |
| `gcr.io/distroless/java25-debian13` | No | No | Low |
| `alpine` | Yes | Yes (apk) | Low |
| `eclipse-temurin:25-jre-alpine` | Yes | Yes (apk) | Medium |

## Image Scanning

Scan your images regularly for CVEs:

```bash
# Using Docker Scout
docker scout cves myapp-distroless

# Using Trivy
trivy image myapp-distroless

# Using Grype
grype myapp-distroless
```

## Build Reproducibility

- Pin exact base image tags or digests in CI/CD when reproducibility matters (for example, prefer a fully qualified Temurin tag or image digest instead of a floating major tag)
- Pin Maven/Gradle plugin versions
- Use `--no-cache` for CI builds to avoid stale layers

## Secrets Management

- Never bake secrets into Docker images
- Use Docker secrets, environment variables at runtime, or a secrets manager
- The `.dockerignore` file excludes `.env` files from the build context

## Network Security

- Expose only required ports
- Prefer images without a shell or package manager for production (`distroless` or `scratch` variants)
- Use read-only file systems when possible:
  ```bash
  docker run --read-only --tmpdir /tmp myapp-distroless
  ```

## Resource Limits

Always set resource limits in production:

```bash
docker run -m 512m --cpus="1.0" myapp-distroless
```

## References

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Google Distroless](https://github.com/GoogleContainerTools/distroless)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
