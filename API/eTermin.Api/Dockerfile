FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_HTTP_PORTS=8080
ENV TZ=Europe/Sarajevo
RUN apt-get update && apt-get install -y --no-install-recommends tzdata && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["API/eTermin.Api/eTermin.Api.csproj", "API/eTermin.Api/"]
COPY ["API/Application/eTermin.Application/eTermin.Application.csproj", "API/Application/eTermin.Application/"]
COPY ["API/Domain/eTermin.Domain/eTermin.Domain.csproj", "API/Domain/eTermin.Domain/"]
COPY ["API/Infrastructure/eTermin.Infrastructure/eTermin.Infrastructure.csproj", "API/Infrastructure/eTermin.Infrastructure/"]

RUN dotnet restore "API/eTermin.Api/eTermin.Api.csproj"

COPY . .
WORKDIR /src/API/eTermin.Api
RUN dotnet publish "eTermin.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "eTermin.Api.dll"]
