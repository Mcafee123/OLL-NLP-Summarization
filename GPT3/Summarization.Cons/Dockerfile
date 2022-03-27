FROM mcr.microsoft.com/dotnet/runtime:6.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Summarization.Cons/Summarization.Cons.csproj", "Summarization.Cons/"]
RUN dotnet restore "Summarization.Cons/Summarization.Cons.csproj"
COPY . .
WORKDIR "/src/Summarization.Cons"
RUN dotnet build "Summarization.Cons.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Summarization.Cons.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Summarization.Cons.dll"]
