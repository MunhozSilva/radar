# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

# Stage 2: Runtime
FROM public.ecr.aws/lambda/dotnet:9.0 AS final
WORKDIR /var/task

# Copia app publicado
COPY --from=build /app/publish .

# Lambda Handler
CMD ["radar::Radar.Function::FunctionHandler"]
