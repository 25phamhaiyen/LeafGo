FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY src/LeafGo.API/*.csproj ./src/LeafGo.API/
COPY src/LeafGo.Application/*.csproj ./src/LeafGo.Application/
COPY src/LeafGo.Domain/*.csproj ./src/LeafGo.Domain/
COPY src/LeafGo.Infrastructure/*.csproj ./src/LeafGo.Infrastructure/
RUN dotnet restore src/LeafGo.API/LeafGo.API.csproj
COPY . .

FROM build AS publish
WORKDIR /src/src/LeafGo.API
RUN dotnet publish LeafGo.API.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN adduser --disabled-password --gecos "" appuser
RUN mkdir -p /app/wwwroot/avatars && chown -R appuser /app
USER appuser
COPY --from=publish /app/publish .
EXPOSE 8080
EXPOSE 8081
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "LeafGo.API.dll"]