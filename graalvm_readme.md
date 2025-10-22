# ⚡ GraalVM Native Image Dockerfiles - Ultra Otimizado

Dockerfiles altamente otimizados para aplicações Java compiladas com GraalVM Native Image, focados em **máxima performance e tamanho mínimo**.

## 🚀 Por que GraalVM Native Image?

- **Startup instantâneo**: 10-100x mais rápido que JVM tradicional
- **Menor uso de memória**: 5-10x menos RAM
- **Tamanho reduzido**: Imagens de 15-50MB (vs 150-200MB com JRE)
- **Performance**: Após warm-up, similar ou superior ao JIT

## 📊 Comparação de Tamanhos e Performance

| Dockerfile | Tamanho | Startup | RAM | Build Tool | Caso de Uso |
|-----------|---------|---------|-----|------------|-------------|
| **Scratch + UPX** | ~15-25MB | <50ms | ~50MB | Maven | Máxima otimização |
| **Distroless** | ~25-40MB | <50ms | ~50MB | Maven | Produção segura |
| **Scratch** | ~30-50MB | <50ms | ~50MB | Maven | Mínimo absoluto |
| **Alpine** | ~40-60MB | <50ms | ~60MB | Maven | Debug friendly |
| **Gradle Native** | ~30-50MB | <50ms | ~50MB | Gradle | Projetos Gradle |
| **Spring Native** | ~50-80MB | <100ms | ~70MB | Maven | Spring Boot |
| **JRE Alpine** | ~180MB | ~3-5s | ~150MB | Maven | Comparação JVM |

## 🏗️ Dockerfiles Disponíveis

### 1. `graalvm-upx.Dockerfile` ⭐ (Menor Tamanho Possível)
Binário estático comprimido com UPX - extrema otimização.

**Características:**
- **Tamanho:** 15-25MB
- Compressão UPX (50-70% redução adicional)
- Binário estático (sem dependências)
- Imagem base: `scratch`
- **Melhor para:** Microsserviços, serverless, edge computing

**Build e Run:**
```bash
docker build -t myapp-upx -f graalvm-upx.Dockerfile .
docker run -p 8080:8080 myapp-upx

# Tempo de startup: ~30-50ms
# Uso de RAM: ~50MB
```

### 2. `graalvm-scratch.Dockerfile` (Ultra Mínimo)
Binário estático em imagem vazia - sem sistema operacional.

**Características:**
- **Tamanho:** 30-50MB
- Zero dependências externas
- Máxima segurança (sem vulnerabilidades de OS)
- Inclui CA certificates para HTTPS

**Build e Run:**
```bash
docker build -t myapp-scratch -f graalvm-scratch.Dockerfile .
docker run -p 8080:8080 myapp-scratch
```

### 3. `graalvm-distroless.Dockerfile` (Recomendado)
Google Distroless com binário nativo - balanceado.

**Características:**
- **Tamanho:** 25-40MB
- Máxima segurança (Google Distroless)
- Sem shell ou package managers
- Non-root por padrão

**Build e Run:**
```bash
docker build -t myapp-distroless -f graalvm-distroless.Dockerfile .
docker run -p 8080:8080 myapp-distroless
```

### 4. `graalvm-alpine.Dockerfile` (Debug Friendly)
Alpine Linux com ferramentas de debug.

**Características:**
- **Tamanho:** 40-60MB
- Shell disponível para debug
- Health checks configurados
- gcompat para compatibilidade glibc

**Build e Run:**
```bash
docker build -t myapp-alpine -f graalvm-alpine.Dockerfile .
docker run -p 8080:8080 myapp-alpine

# Debug no container
docker exec -it <container-id> sh
```

### 5. `graalvm-spring-native.Dockerfile` (Spring Boot)
Otimizado para Spring Boot com GraalVM.

**Características:**
- **Tamanho:** 50-80MB
- Spring Boot Native suporte completo
- AOT compilation
- Reflection hints inclusos

**Build e Run:**
```bash
docker build -t myapp-spring -f graalvm-spring-native.Dockerfile .
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=prod myapp-spring
```

### 6. `graalvm-gradle.Dockerfile` (Projetos Gradle)
Específico para Gradle com Native Image.

**Características:**
- **Tamanho:** 30-50MB
- Gradle 8.5+
- Cache de dependências otimizado

**Build e Run:**
```bash
docker build -t myapp-gradle -f graalvm-gradle.Dockerfile .
docker run -p 8080:8080 myapp-gradle
```

## 🔧 Configurações Maven para Native Image

### pom.xml - Quarkus
```xml
<profiles>
  <profile>
    <id>native</id>
    <properties>
      <quarkus.package.type>native</quarkus.package.type>
      <quarkus.native.additional-build-args>
        --static,
        --libc=musl,
        -H:+ReportExceptionStackTraces,
        -H:+PrintClassInitialization
      </quarkus.native.additional-build-args>
    </properties>
  </profile>
</profiles>
```

### pom.xml - Spring Boot Native
```xml
<profiles>
  <profile>
    <id>native</id>
    <build>
      <plugins>
        <plugin>
          <groupId>org.graalvm.buildtools</groupId>
          <artifactId>native-maven-plugin</artifactId>
          <version>0.10.1</version>
          <executions>
            <execution>
              <goals>
                <goal>compile-no-fork</goal>
              </goals>
            </execution>
          </executions>
        </plugin>
      </plugins>
    </build>
  </profile>
</profiles>
```

## 🔧 Configurações Gradle para Native Image

### build.gradle
```gradle
plugins {
    id 'org.graalvm.buildtools.native' version '0.10.1'
}

graalvmNative {
    binaries {
        main {
            imageName = 'application'
            buildArgs.add('--static')
            buildArgs.add('--libc=musl')
            buildArgs.add('-H:+ReportExceptionStackTraces')
        }
    }
}
```

## 🎯 Build Multi-Plataforma

```bash
# Criar builder
docker buildx create --use --name graalbuilder --driver docker-container

# Bootstrap
docker buildx inspect graalbuilder --bootstrap

# Build para AMD64 (mais comum)
docker buildx build --platform linux/amd64 \
  -t myapp-native:amd64 \
  -f graalvm-distroless.Dockerfile \
  --load .

# Build para ARM64
docker buildx build --platform linux/arm64 \
  -t myapp-native:arm64 \
  -f graalvm-distroless.Dockerfile \
  --load .

# Build e push multi-plataforma
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myuser/myapp-native:latest \
  -f graalvm-distroless.Dockerfile \
  --push .
```

## 📋 Requisitos do Projeto

### Para Quarkus
```xml
<dependency>
  <groupId>io.quarkus</groupId>
  <artifactId>quarkus-resteasy-reactive</artifactId>
</dependency>
```

### Para Spring Boot
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.experimental</groupId>
  <artifactId>spring-native</artifactId>
</dependency>
```

## 🚀 Comparação: Native vs JVM

### Exemplo Real - API REST Simples

| Métrica | GraalVM Native | JVM (OpenJDK) |
|---------|----------------|---------------|
| **Imagem Docker** | 25 MB | 180 MB |
| **Tempo de Startup** | 35 ms | 4.5 s |
| **Uso de RAM** | 55 MB | 150 MB |
| **Tempo de Build** | 3-5 min | 30-60 s |
| **First Request** | 10 ms | 50-100 ms |

## 💡 Boas Práticas

### 1. Reflection Configuration
GraalVM precisa saber em tempo de build sobre reflection:

```json
// reflect-config.json
[
  {
    "name": "com.myapp.MyClass",
    "allDeclaredConstructors": true,
    "allPublicMethods": true
  }
]
```

### 2. Resource Configuration
Inclua recursos necessários:

```json
// resource-config.json
{
  "resources": {
    "includes": [
      {"pattern": "application.properties"},
      {"pattern": "templates/.*"}
    ]
  }
}
```

### 3. Build Time Optimization
```bash
# Maven
mvn clean package -Pnative -DskipTests \
  -Dquarkus.native.additional-build-args=-march=native

# Para máxima otimização (build mais lento)
-Dquarkus.native.additional-build-args=-O3,-march=native
```

## 🐛 Debug e Troubleshooting

### Testar localmente com GraalVM
```bash
# Instalar GraalVM
sdk install java 21.0.1-graal

# Build local
mvn clean package -Pnative

# Executar
./target/myapp-runner
```

### Gerar configs de reflection automaticamente
```bash
# Com agent do GraalVM
java -agentlib:native-image-agent=config-output-dir=src/main/resources/META-INF/native-image \
  -jar target/myapp.jar
```

### Inspecionar tamanho do binário
```bash
# Ver seções do binário
size target/myapp-runner

# Análise detalhada
nm -S target/myapp-runner | sort -n -k 2
```

## 📊 Métricas de Produção

### Kubernetes Resource Limits
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### Docker Compose
```yaml
services:
  app:
    image: myapp-native:latest
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.5'
```

## ⚠️ Limitações do Native Image

1. **Reflection limitada**: Precisa configurar em advance
2. **Dynamic class loading**: Não suportado
3. **JNI**: Requer configuração especial
4. **JVMTI/Agents**: Não disponíveis
5. **Tempo de build**: 3-10x mais longo que JVM

## 🎯 Quando Usar GraalVM Native?

### ✅ Ideal para:
- Microsserviços com tráfego variável
- Serverless / AWS Lambda
- CLI tools
- Edge computing
- Containers efêmeros
- Kubernetes com autoscaling

### ❌ Evitar quando:
- Aplicações monolíticas grandes
- Heavy reflection/dynamic loading
- Frameworks não suportados
- Time de build crítico

## 📚 Recursos Adicionais

- [GraalVM Official](https://www.graalvm.org/)
- [Quarkus Native Guide](https://quarkus.io/guides/building-native-image)
- [Spring Native Docs](https://docs.spring.io/spring-native/docs/current/reference/htmlsingle/)
- [Native Image Build Options](https://www.graalvm.org/latest/reference-manual/native-image/overview/BuildOptions/)
- [UPX Compressor](https://upx.github.io/)

## 🏆 Recordes de Otimização

Com as melhores práticas:
- **Menor imagem**: 12MB (Quarkus + UPX + Scratch)
- **Startup mais rápido**: 15ms (CLI tool simples)
- **Menor RAM**: 30MB (API REST básica)

---

**Dica Final:** Comece com `graalvm-distroless.Dockerfile` e otimize conforme necessário!