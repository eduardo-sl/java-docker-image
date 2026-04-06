# Stage 1: Build the native image with GraalVM
FROM ghcr.io/graalvm/native-image-community:21-muslib-ol9 AS builder

WORKDIR /build

# Install Maven
RUN microdnf install -y maven && microdnf clean all

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the native image
COPY sample-app/src ./src
RUN mvn -Pnative clean package -DskipTests -B native:compile

# Stage 2: Create the final image
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy the native binary
COPY --from=builder /build/target/demo /app/application

# Expose the application port
EXPOSE 8080

# Distroless runs as non-root by default
ENTRYPOINT ["/app/application"]
