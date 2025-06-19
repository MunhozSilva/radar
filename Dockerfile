# -------------------------
# Stage 1: Build da aplicação
# -------------------------
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copia o csproj e restaura dependências
COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"

# Copia o restante e publica
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# -------------------------
# Stage 2: Base com Google Chrome + dependências
# -------------------------
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app

# Instala bibliotecas necessárias para o ChromeDriver funcionar
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg fontconfig libx11-dev libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 libnspr4 libnss3 \
    libxcomposite1 libxdamage1 libxrandr2 xdg-utils unzip libgbm1 libxshmfence-dev \
    && rm -rf /var/lib/apt/lists/*

# Adiciona repositório e instala o Google Chrome
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Instala o ChromeDriver manualmente na versão compatível
RUN set -eux; \
    CHROMEDRIVER_VERSION=$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE); \
    echo "ChromeDriver version: $CHROMEDRIVER_VERSION"; \
    curl -fsSL -o /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"; \
    unzip /tmp/chromedriver.zip -d /usr/local/bin/; \
    rm /tmp/chromedriver.zip; \
    chmod +x /usr/local/bin/chromedriver

# -------------------------
# Stage 3: Final - Lambda com app + Chrome
# -------------------------
FROM public.ecr.aws/lambda/dotnet:9 AS final
WORKDIR /var/task

# Copia o Chrome e ChromeDriver do stage base
COPY --from=base /usr/bin/google-chrome-stable /usr/bin/google-chrome
COPY --from=base /usr/local/bin/chromedriver /usr/local/bin/chromedriver

# Copia apenas as bibliotecas necessárias para o Chrome funcionar
COPY --from=base /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=base /lib/x86_64-linux-gnu /lib/x86_64-linux-gnu

# Copia app publicado
COPY --from=build /app/publish .

# Define o handler da AWS Lambda
CMD ["radar::Radar.Function::FunctionHandler"]
