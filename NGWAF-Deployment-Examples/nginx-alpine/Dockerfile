FROM openresty/openresty:1.21.4.1-0-alpine-apk

ARG DEST="/opt/sigsci"
ARG NGLUA_URL="https://dl.signalsciences.net/sigsci-module-nginx/sigsci-module-nginx_latest.tar.gz"

# ENV SIGSCI_ACCESSKEYID=""
# ENV SIGSCI_SECRETACCESSKEY=""
# ENV SIGSCI_WAF_DATA_LOG="/dev/stdout"


RUN apk update && apk add wget curl \
    && wget -q https://apk.signalsciences.net/sigsci_apk.pub ; mv sigsci_apk.pub /etc/apk/keys

# && echo "https://apk.signalsciences.net/$(sed 's/..$//' /etc/alpine-release)/main" | tee -a /etc/apk/repositories && apk update  \
# && apk add sigsci-agent

RUN wget -q https://apk.signalsciences.net/3.18/main/x86_64/sigsci-agent-4.49.0.apk
RUN apk add --allow-untrusted sigsci-agent-4.49.0.apk


COPY agent.conf /etc/sigsci/agent.conf

RUN mkdir -p ${DEST} && \
    curl -L ${NGLUA_URL} -o ${DEST}/sigsci-module-nginx.tar.gz && \
    tar -xzvf ${DEST}/sigsci-module-nginx.tar.gz -C ${DEST} && \
    mv ${DEST}/sigsci-module-nginx ${DEST}/nginx && \
    rm ${DEST}/sigsci-module-nginx.tar.gz



RUN ln -s "/opt/sigsci/nginx/sigsci.conf" "/etc/nginx/conf.d/sigsci.conf"

CMD /bin/sh -c "/usr/sbin/sigsci-agent & /usr/local/openresty/bin/openresty -g 'daemon off;'"