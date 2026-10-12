ARG DOTNET_SDK_IMAGE=mcr.microsoft.com/dotnet/sdk@sha256:e70cdb7f80b0348f5cb85f19a8f670fca061f033d57eed12fa003d58b0e06317
ARG DOTNET_RUNTIME_IMAGE=mcr.microsoft.com/dotnet/runtime@sha256:b89586dc17781f25531909993658aa8161205ae38b8cec8847df4a8221a403d5

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
