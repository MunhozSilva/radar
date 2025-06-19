# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# Stage 2: Chrome com dependências
FROM ubuntu:22.04 AS chrome

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg fontconfig libx11-dev libxss1 libappindicator3-1 libasound2 \
    libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 libnspr4 libnss3 \
    libxcomposite1 libxdamage1 libxrandr2 xdg-utils unzip \
    && rm -rf /var/lib/apt/lists/*

# Instala Chrome
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/chrome.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && apt-get install -y google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

# ChromeDriver
RUN CHROMEDRIVER_VERSION=$(curl -sSL https://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
 && curl -fsSL -o /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip \
 && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
 && chmod +x /usr/local/bin/chromedriver \
 && rm /tmp/chromedriver.zip

# Stage 3: Lambda
FROM public.ecr.aws/lambda/dotnet:9 AS final
WORKDIR /var/task

# Copia app publicado
COPY --from=build /app/publish .

# Copia apenas o Chrome e o ChromeDriver
COPY --from=chrome /usr/bin/google-chrome-stable /usr/bin/google-chrome
COPY --from=chrome /usr/local/bin/chromedriver /usr/local/bin/chromedriver

# Copia as libs exatas (sem o /lib inteiro, que quebra tudo)
COPY --from=chrome /lib/x86_64-linux-gnu /lib/x86_64-linux-gnu
COPY --from=chrome /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu

# Lambda handler
CMD ["radar::Radar.Function::FunctionHandler"]
