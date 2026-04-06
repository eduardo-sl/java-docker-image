# Stage 1: Build the application
FROM docker.io/maven:3.9-eclipse-temurin-25-alpine AS builder

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

# Stage 2: Create the final image
FROM gcr.io/distroless/java25-debian13:nonroot

WORKDIR /app

# Copy the JAR from builder
COPY --from=builder /build/app.jar /app/app.jar

# Expose the application port
EXPOSE 8080

# Distroless images run as non-root by default (uid 65534)
# Run with optimized JVM flags for containers
ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+UseG1GC", \
    "-XX:+UseStringDeduplication", \
    "-XX:+ExitOnOutOfMemoryError", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "/app/app.jar"]
