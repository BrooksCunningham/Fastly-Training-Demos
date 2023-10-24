# Build the image
# docker build . -t mylocaltrainingimages/dotnet-module

# Pull the microsoft container, https://hub.docker.com/_/microsoft-dotnet-samples/
FROM mcr.microsoft.com/dotnet/samples:aspnetapp

# update packages for Alpine Linux
RUN apk update
RUN apk upgrade

# # install packages for troubleshooting
RUN apk add curl
RUN apk add vim

# RUN curl https://dl.signalsciences.net/sigsci-module-dotnetcore/1.3.1/SignalSciences.Module.DotNetCore.1.3.1.nupkg --output /app/SignalSciences.Module.DotNetCore.1.3.1.nupkg

# RUN dotnet add package SignalSciences.HttpMiddleware -s /app/SignalSciences.Module.DotNetCore.1.3.1.nupkg
WORKDIR /app
ENTRYPOINT [ "./aspnetapp" ]