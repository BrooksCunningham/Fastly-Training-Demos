FROM alpine:3.17
ARG url="https://dl.signalsciences.net/sigsci-module-nginx/sigsci-module-nginx_latest.tar.gz"
ARG destination="/opt/sigsci"

# COPY install.sh /opt

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN apk update \
    && apk add wget \
    && apk add curl \
    && apk add nginx \
    && apk add nginx-mod-http-lua

WORKDIR /opt/sigsci
RUN curl -L "$url" -o "$destination/sigsci-module-nginx.tar.gz"
RUN tar -xzvf "$destination/sigsci-module-nginx.tar.gz" -C "$destination"
RUN mv "$destination/sigsci-module-nginx" "$destination/nginx"
RUN rm "$destination/sigsci-module-nginx.tar.gz"

RUN ln -s "/opt/sigsci/nginx/sigsci.conf" "/etc/nginx/http.d/sigsci.conf"

COPY default.conf /etc/nginx/http.d/default.conf

# RUN chmod +x /opt/install.sh && sh /opt/install.sh
COPY sigsci_check_lua.conf /opt/sigsci/nginx/sigsci_check_lua.conf

# Create the target directory for agent.conf
RUN mkdir -p /etc/sigsci
COPY agent.conf /etc/sigsci/

# RUN apk update && apk add wget \
RUN echo https://apk.signalsciences.net/$(sed 's/...$//' /etc/alpine-release)/main

RUN wget -q https://apk.signalsciences.net/sigsci_apk.pub ; mv sigsci_apk.pub /etc/apk/keys
# RUN echo https://apk.signalsciences.net/$(sed 's/...$//' /etc/alpine-release)/main | tee -a /etc/apk/repositories
RUN echo https://apk.signalsciences.net/3.17/main | tee -a /etc/apk/repositories
RUN apk update
RUN apk add sigsci-agent

RUN cat /etc/apk/repositories

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]