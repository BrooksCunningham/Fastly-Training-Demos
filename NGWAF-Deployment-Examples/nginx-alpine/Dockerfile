FROM alpine:3.15
ARG url="https://dl.signalsciences.net/sigsci-module-nginx/sigsci-module-nginx_latest.tar.gz"
ARG destination="/opt/sigsci"

COPY install.sh /opt

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
RUN wget -q https://apk.signalsciences.net/sigsci_apk.pub ; mv sigsci_apk.pub /etc/apk/keys \
    && echo https://apk.signalsciences.net/$(sed 's/...$//' /etc/alpine-release)/main | tee -a /etc/apk/repositories && apk update  \
    && apk add sigsci-agent

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]