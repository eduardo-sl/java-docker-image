# Stage 1: Build the application
FROM docker.io/maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN --mount=type=cache,target=/root/.m2/repository \
    mvn dependency:go-offline -B

# Copy source code and build
COPY sample-app/src ./src
RUN --mount=type=cache,target=/root/.m2/repository \
    mvn clean package -DskipTests -B && \
    mv target/*.jar app.jar

# Stage 2: Create a custom JRE with jlink
FROM docker.io/eclipse-temurin:21-jdk-alpine AS jlink-builder

WORKDIR /jlink

# Copy the JAR to analyze module dependencies
COPY --from=builder /build/app.jar app.jar

# Analyze dependencies and create a minimal custom JRE
# jdeps identifies required modules; jlink strips everything else
RUN jdeps --ignore-missing-deps \
        --print-module-deps \
        --multi-release 21 \
        app.jar > /tmp/modules.txt && \
    jlink \
        --add-modules $(cat /tmp/modules.txt),jdk.crypto.ec,jdk.management \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=zip-6 \
        --output /jre-custom

# Stage 3: Create the final minimal image
FROM docker.io/alpine:3.21

# Install only essential runtime dependencies
RUN apk add --no-cache \
        ca-certificates \
        tzdata && \
    addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

WORKDIR /app

# Copy the custom JRE and the application JAR
COPY --from=jlink-builder /jre-custom /opt/jre
COPY --from=builder /build/app.jar /app/app.jar

ENV JAVA_HOME=/opt/jre
ENV PATH="$JAVA_HOME/bin:$PATH"

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run with the custom JRE and optimized flags
ENTRYPOINT ["/opt/jre/bin/java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+UseG1GC", \
    "-XX:+UseStringDeduplication", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "/app/app.jar"]
