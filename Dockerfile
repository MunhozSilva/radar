# Stage 1: Build da aplicação
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# Stage 2: Base com Chrome, ChromeDriver e dependências gráficas
FROM ubuntu:22.04 AS base
WORKDIR /app

# Instala dependências do Chrome e libs gráficas
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg unzip fontconfig libx11-dev libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 libnspr4 libnss3 \
    libxcomposite1 libxdamage1 libxrandr2 libgtk-3-0 libgdk-3-0 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Adiciona repositório oficial do Chrome e instala
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Instala ChromeDriver compatível com o Chrome
RUN CHROMEDRIVER_VERSION=$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
    && curl -fsSL -o /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip" \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/chromedriver \
    && rm /tmp/chromedriver.zip

# Stage final: imagem Lambda
FROM public.ecr.aws/lambda/dotnet:9 AS final
WORKDIR /var/task

# Copia Chrome e ChromeDriver
COPY --from=base /usr/bin/google-chrome-stable /usr/bin/google-chrome
COPY --from=base /usr/local/bin/chromedriver /usr/local/bin/chromedriver

# Copia libs necessárias
COPY --from=base /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/
COPY --from=base /usr/lib/x86_64-linux-gnu/libdbus-1.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=base /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/

# Copia app publicado
COPY --from=build /app/publish .

# Handler Lambda
CMD ["radar::Radar.Function::FunctionHandler"]
