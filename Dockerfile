# Stage 1: Build (SDK do .NET 9)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copia o arquivo do projeto e restaura dependências
COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"

# Copia o código e publica a aplicação
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# Stage 2: Runtime base (runtime + libs para Chrome e ChromeDriver)
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app

# Instala dependências para o Chrome
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
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Instala o Google Chrome
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
       | tee /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Instala o ChromeDriver em versao fixa
ENV CHROMEDRIVER_VERSION=125.0.6422.78
RUN curl -Lo /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip" \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
    && rm /tmp/chromedriver.zip \
    && chmod +x /usr/local/bin/chromedriver

# Stage 3: Lambda final (app publicado + runtime + Chrome)
FROM public.ecr.aws/lambda/dotnet:9 AS final
WORKDIR /var/task

# Copia runtime + libs do Stage base (runtime + Chrome)
COPY --from=base /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable
COPY --from=base /usr/local/bin/chromedriver /usr/local/bin/chromedriver
COPY --from=base /etc/apt/keyrings/google-chrome.gpg /etc/apt/keyrings/google-chrome.gpg
COPY --from=base /etc/apt/sources.list.d/google-chrome.list /etc/apt/sources.list.d/google-chrome.list

# Copia app publicado
COPY --from=build /app/publish .

# Comando default da Lambda
CMD ["Radar.Function::FunctionHandler"]
