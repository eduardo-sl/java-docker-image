# Stage 1: Build the native image with GraalVM and compress with UPX
FROM ghcr.io/graalvm/native-image-community:25-ol9 AS builder

WORKDIR /build

# Install only the tools needed to fetch Maven and UPX
ARG MAVEN_VERSION=3.9.9
ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

RUN microdnf install -y wget xz && \
    wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-maven-${MAVEN_VERSION} "${MAVEN_HOME}" && \
    wget -q https://github.com/upx/upx/releases/download/v4.2.4/upx-4.2.4-amd64_linux.tar.xz && \
    tar -xf upx-4.2.4-amd64_linux.tar.xz && \
    mv upx-4.2.4-amd64_linux/upx /usr/local/bin/ && \
    rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz upx-* && \
    microdnf clean all

# Copy dependency descriptor first for better layer caching
COPY sample-app/pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the native image
COPY sample-app/src ./src
RUN mvn -Pnative clean package -DskipTests -B native:compile

# Compress the binary with UPX (reduces size by 50-70%)
RUN upx --best --lzma /build/target/demo

# Stage 2: Create the final image with a minimal runtime
FROM gcr.io/distroless/cc-debian13:nonroot

WORKDIR /app

# Copy the compressed native binary
COPY --from=builder /build/target/demo /app/application

EXPOSE 8080

ENTRYPOINT ["/app/application"]
