ARG DOTNET_SDK_IMAGE=mcr.microsoft.com/dotnet/sdk@sha256:e70cdb7f80b0348f5cb85f19a8f670fca061f033d57eed12fa003d58b0e06317
ARG DOTNET_RUNTIME_IMAGE=mcr.microsoft.com/dotnet/runtime@sha256:939555726cae4c916d212323ac3c0792996dcac2614f00e82cc40fcf059e1af3

FROM --platform=$BUILDPLATFORM ${DOTNET_SDK_IMAGE} AS build

ARG TARGETARCH

WORKDIR /source

COPY *.csproj .
RUN dotnet restore --arch "$TARGETARCH"

COPY . .
RUN dotnet publish --configuration Release \
    --output /app \
    --arch "$TARGETARCH" \
    --self-contained false \
    --no-restore

FROM ${DOTNET_RUNTIME_IMAGE} AS final

WORKDIR /app

COPY --from=build /app .

USER app

ENTRYPOINT ["dotnet", "Worker.dll"]
