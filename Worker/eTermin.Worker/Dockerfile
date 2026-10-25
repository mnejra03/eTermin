FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app
ENV TZ=Europe/Sarajevo
RUN apt-get update && apt-get install -y --no-install-recommends tzdata && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["Worker/eTermin.Worker/eTermin.Worker.csproj", "Worker/eTermin.Worker/"]
COPY ["API/Application/eTermin.Application/eTermin.Application.csproj", "API/Application/eTermin.Application/"]
COPY ["API/Domain/eTermin.Domain/eTermin.Domain.csproj", "API/Domain/eTermin.Domain/"]
COPY ["API/Infrastructure/eTermin.Infrastructure/eTermin.Infrastructure.csproj", "API/Infrastructure/eTermin.Infrastructure/"]
RUN dotnet restore "Worker/eTermin.Worker/eTermin.Worker.csproj"

COPY . .
WORKDIR /src/Worker/eTermin.Worker
RUN dotnet publish "eTermin.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "eTermin.Worker.dll"]
