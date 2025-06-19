# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish


# Stage 2: Base com Chrome + dependências
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app

# Instala dependências do Chrome e do ChromeDriver
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg fontconfig libx11-dev libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 libnspr4 libnss3 \
    libxcomposite1 libxdamage1 libxrandr2 xdg-utils unzip \
    && rm -rf /var/lib/apt/lists/*

# Instala o Google Chrome
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Instala o ChromeDriver
RUN set -eux; \
    CHROMEDRIVER_VERSION=$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE); \
    echo "ChromeDriver version: $CHROMEDRIVER_VERSION"; \
    curl -fsSL -o /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"; \
    unzip /tmp/chromedriver.zip -d /usr/local/bin/; \
    rm /tmp/chromedriver.zip; \
    chmod +x /usr/local/bin/chromedriver


# Stage 3: Lambda com app publicado e bibliotecas do Chrome
FROM public.ecr.aws/lambda/dotnet:9 AS final
WORKDIR /var/task

# Copia Chrome + ChromeDriver
COPY --from=base /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable
COPY --from=base /usr/local/bin/chromedriver /usr/local/bin/chromedriver

# Copia as bibliotecas necessárias para execução do ChromeDriver
COPY --from=base /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libx11.so.6 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/ || true
COPY --from=base /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/ || true
COPY --from=base /usr/lib/x86_64-linux-gnu/libdbus-1.so.3 /usr/lib/x86_64-linux-gnu/

# Copia o app publicado
COPY --from=build /app/publish .

# Define o Lambda Handler
CMD ["radar::Radar.Function::FunctionHandler"]
