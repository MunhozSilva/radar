FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

COPY ["radar.csproj", "./"]
RUN dotnet restore "radar.csproj"
COPY . .
RUN dotnet publish "radar.csproj" -c Release -o /app/publish

FROM public.ecr.aws/lambda/dotnet:6.0
WORKDIR /var/task

COPY --from=build /app/publish .

CMD ["radar::Radar.Function::FunctionHandler"]
