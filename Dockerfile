# Stage 1: Runtime base
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app

# Instala dependências para o Chrome e o ChromeDriver
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    fontconfig \
    libx11-dev \
    libxss1 \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    unzip \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Instala o Google Chrome
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | tee /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Instala o ChromeDriver compatível com a versão do Chrome
RUN CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d '.' -f 1) \
    && CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}") \
    && curl -Lo /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
    && rm /tmp/chromedriver.zip \
    && chmod +x /usr/local/bin/chromedriver

# Stage 2: Build + Publish
FROM public.ecr.aws/lambda/dotnet:9 AS build
WORKDIR /src

# Copia e restaura dependências
COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"

# Copia tudo e compila
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# Stage 3: Final - Lambda com código publicado + dependências Chrome
FROM base AS final
WORKDIR /var/task

# Copia o app publicado para o diretório de execução da Lambda
COPY --from=build /app/publish .

# Define o entrypoint da Lambda
CMD ["Radar.Function::FunctionHandler"]
