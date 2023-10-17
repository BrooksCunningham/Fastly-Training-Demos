# Build the image
# docker build . -t bcunningham/nginx-module

# Pull the minimal Ubuntu image
FROM ubuntu:20.04

# Install Nginx
RUN apt-get -y update && apt-get -y install nginx=1.18.0-0ubuntu1.4

# copy config and app over
RUN  mkdir /app
COPY nginx-config/nginx.conf /etc/nginx/nginx.conf
# COPY app/default.conf /etc/nginx/sites-enabled/default.conf
# COPY start.sh /app/start.sh
# RUN chmod +x /app/start.sh


# For manually modifying files
RUN apt-get -y install vim

# Copy the Nginx config
# COPY default /etc/nginx/sites-available/default
# RUN nginx -v

# Expose the port for access
# EXPOSE 80/tcp

RUN apt-get update
RUN apt-get install -y apt-transport-https wget gnupg
# RUN wget -qO - https://apt.signalsciences.net/release/gpgkey | gpg --dearmor -o /usr/share/keyrings/sigsci.gpg
# RUN echo "deb [signed-by=/usr/share/keyrings/sigsci.gpg] https://apt.signalsciences.net/release/ubuntu/ jammy main" | tee /etc/apt/sources.list.d/sigsci-release.list 


RUN wget -qO - https://apt.signalsciences.net/release/gpgkey | apt-key add -
RUN echo "deb https://apt.signalsciences.net/release/ubuntu/ focal main" | tee /etc/apt/sources.list.d/sigsci-release.list && apt-get update


# Install the module, https://dl.signalsciences.net/?prefix=sigsci-module-nginx-native/1.1.7/ubuntu/jammy/
ARG MODULE_VERSION="1.18.0-427"
RUN apt-get install nginx-module-sigsci-nxo=${MODULE_VERSION}
# apt-get install nginx-module-sigsci-nxo=1.18.0-427

# Using /usr/sbin/nginx 1.18.0 to link modules
# Found nginx modules in /usr/lib/nginx/modules. Linking to version 1.18.0
# Have /usr/share/nginx so prepare libs:
# Set links in /usr/share/nginx/modules:
# total 468
# lrwxrwxrwx 1 root root     29 May  9 15:04 ndk_http_module.so -> ndk_http_nxo_module-1.18.0.so
# -rwxrwxrwx 1 root root  14200 Sep 27  2022 ndk_http_nxo_module-1.18.0.so
# -rw-r--r-- 1 root root  27728 Nov 10 06:38 ngx_http_image_filter_module.so
# lrwxrwxrwx 1 root root     59 May  9 15:17 ngx_http_sigsci_module.so -> /usr/lib/nginx/modules/ngx_http_sigsci_nxo_module-1.18.0.so
# -rwxrwxrwx 1 root root 113904 Sep 27  2022 ngx_http_sigsci_nxo_module-1.18.0.so
# -rw-r--r-- 1 root root  23552 Nov 10 06:38 ngx_http_xslt_filter_module.so
# -rw-r--r-- 1 root root 108168 Nov 10 06:38 ngx_mail_module.so
# -rw-r--r-- 1 root root 180792 Nov 10 06:38 ngx_stream_module.so
#


# RUN apt-get install nginx-module-sigsci-nxo=1.23.4-498

# Find the different versions available with the following command
# apt-cache madison nginx-module-sigsci-nxo

# Run the Nginx server
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]