# 🚀 Dockerfiles Otimizados para Java

Dockerfiles altamente otimizados para aplicações Java, baseados no conceito de multi-stage builds e imagens mínimas.

## 📊 Comparação de Tamanhos

| Imagem | Tamanho Aproximado | Build Tool | Caso de Uso |
|--------|-------------------|------------|-------------|
| **Distroless** | ~200MB | Maven | Produção (máxima segurança) |
| **Alpine JRE** | ~180MB | Maven | Produção (balanceado) |
| **JLink Custom** | ~100-150MB | Maven | Produção (ultra otimizado) |
| **Gradle Distroless** | ~200MB | Gradle | Produção com Gradle |

## 🏗️ Dockerfiles Disponíveis

### 1. `distroless.Dockerfile` (Recomendado para Produção)
Usa Google Distroless - sem shell, package managers ou bibliotecas desnecessárias.

**Características:**
- Máxima segurança (superfície de ataque mínima)
- Sem vulnerabilidades de sistema operacional
- Ideal para ambientes regulados
- Executa como usuário não-root por padrão

**Build e Run:**
```bash
docker build -t myapp-distroless -f distroless.Dockerfile .
docker run -p 8080:8080 myapp-distroless
```

### 2. `alpine.Dockerfile` (Balanceado)
Alpine Linux com JRE - mínimo mas com ferramentas de debug.

**Características:**
- Inclui shell para debug
- Health checks configurados
- Timezone e certificados CA inclusos
- Usuário não-root customizado

**Build e Run:**
```bash
docker build -t myapp-alpine -f alpine.Dockerfile .
docker run -p 8080:8080 myapp-alpine
```

### 3. `jlink.Dockerfile` (Menor Tamanho)
JRE customizado com apenas módulos necessários via JLink.

**Características:**
- Menor tamanho de imagem possível
- JRE sob medida para sua aplicação
- Tempo de inicialização mais rápido
- Requer Java 9+ com módulos

**Build e Run:**
```bash
docker build -t myapp-jlink -f jlink.Dockerfile .
docker run -p 8080:8080 myapp-jlink
```

### 4. `gradle-distroless.Dockerfile` (Projetos Gradle)
Específico para projetos Gradle com Distroless.

**Características:**
- Otimizado para Gradle
- Cache de dependências eficiente
- Distroless runtime

**Build e Run:**
```bash
docker build -t myapp-gradle -f gradle-distroless.Dockerfile .
docker run -p 8080:8080 myapp-gradle
```

## 🔧 Otimizações JVM Incluídas

Todos os Dockerfiles incluem flags JVM otimizadas:

```java
-XX:+UseContainerSupport          // Detecta limites do container
-XX:MaxRAMPercentage=75.0         // Usa 75% da RAM disponível
-XX:+UseG1GC                      // Garbage Collector G1
-XX:+UseStringDeduplication       // Deduplica strings na heap
-Djava.security.egd=file:/dev/./urandom  // Entropia não-bloqueante
```

## 🌍 Build Multi-Plataforma com Buildx

```bash
# Criar builder
docker buildx create --use --name javabuilder --driver docker-container

# Bootstrap
docker buildx inspect javabuilder --bootstrap

# Build para AMD64
docker buildx build --platform linux/amd64 -t myapp-amd64 -f distroless.Dockerfile --load .

# Build para ARM64
docker buildx build --platform linux/arm64 -t myapp-arm64 -f distroless.Dockerfile --load .

# Build e push para múltiplas plataformas
docker buildx build --platform linux/amd64,linux/arm64 -t myuser/myapp:latest -f distroless.Dockerfile --push .
```

## 📝 Estrutura de Projeto Esperada

### Para Maven:
```
.
├── pom.xml
├── src/
│   └── main/
│       └── java/
└── distroless.Dockerfile
```

### Para Gradle:
```
.
├── build.gradle
├── settings.gradle
├── gradlew
├── gradle/
├── src/
│   └── main/
│       └── java/
└── gradle-distroless.Dockerfile
```

## 🎯 Qual Dockerfile Usar?

| Cenário | Dockerfile Recomendado |
|---------|------------------------|
| Produção com segurança máxima | `distroless.Dockerfile` |
| Precisa de debug/shell | `alpine.Dockerfile` |
| Otimização extrema de tamanho | `jlink.Dockerfile` |
| Projeto Gradle | `gradle-distroless.Dockerfile` |

## 🔒 Segurança

Todas as imagens:
- ✅ Executam como usuário não-root
- ✅ Sem ferramentas desnecessárias
- ✅ Superfície de ataque mínima
- ✅ Certificados CA atualizados

## 💡 Dicas de Performance

1. **Use cache de layers**: Copie `pom.xml` antes do código fonte
2. **Health checks**: Configure para Kubernetes/Docker Swarm
3. **Resource limits**: Defina limites de CPU/RAM no deploy
4. **JVM tuning**: Ajuste `MaxRAMPercentage` baseado em seus recursos

## 📚 Recursos Adicionais

- [Google Distroless](https://github.com/GoogleContainerTools/distroless)
- [Eclipse Temurin](https://adoptium.net/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [JLink Documentation](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jlink.html)