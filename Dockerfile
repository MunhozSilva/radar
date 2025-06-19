# Stage 1: Build .NET app
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# Stage 2: Chrome & ChromeDriver em Ubuntu
FROM ubuntu:22.04 AS chrome

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg unzip \
    libnss3 libx11-6 libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 \
    libgdk-pixbuf2.0-0 libnspr4 libxcomposite1 libxdamage1 libxrandr2 xdg-utils fontconfig

# Instala Google Chrome
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/chrome.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update && apt-get install -y google-chrome-stable

# Instala ChromeDriver
RUN CHROMEDRIVER_VERSION=$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
 && curl -fsSL -o /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip \
 && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
 && chmod +x /usr/local/bin/chromedriver \
 && rm /tmp/chromedriver.zip

# Copia binário e dependências específicas (libnss3 incluída)
RUN mkdir -p /opt/chrome && \
    cp /usr/bin/google-chrome-stable /opt/chrome/google-chrome && \
    cp /usr/local/bin/chromedriver /opt/chrome/chromedriver && \
    ldd /opt/chrome/chromedriver | awk '{print $3}' | grep -v '^(' | xargs -I '{}' cp -v --parents '{}' /opt/chrome/

# Stage final: Lambda
FROM public.ecr.aws/lambda/dotnet:9 AS final
WORKDIR /var/task

# App publicado
COPY --from=build /app/publish .

# Copia Chrome, ChromeDriver e libs exatas
COPY --from=chrome /opt/chrome /opt/chrome

# Adiciona ao PATH
ENV PATH="/opt/chrome:${PATH}"

# Lambda Handler
CMD ["radar::Radar.Function::FunctionHandler"]
