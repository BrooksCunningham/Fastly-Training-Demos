FROM nginx:1.25.3-alpine3.18

RUN wget -q https://apk.signalsciences.net/sigsci_apk.pub && mv sigsci_apk.pub /etc/apk/keys/
RUN echo https://apk.signalsciences.net/3.18/main | tee -a /etc/apk/repositories && apk update
#RUN openssl rsa -pubin -in /etc/apk/keys/sigsci_apk.pub -text -noout
RUN mkdir -p /etc/sigsci
    
# Install required packages
RUN apk update && \
    apk add wget openssl && \
    apk add sigsci-agent && \
    apk add nginx-module-sigsci-nxo-1.25.3

#RUN rm /etc/nginx/conf.d/default.conf
#COPY nginx.conf /etc/nginx/conf.d/

# RUN sed -i 's@^pid.*@&\nload_module /usr/lib/nginx/modules/ngx_http_sigsci_module.so;\n@' /etc/nginx/nginx.conf \
#     && sed -i 's@^pid.*@&\nload_module /usr/lib/nginx/modules/ndk_http_module.so;\n@' /etc/nginx/nginx.conf 

COPY nginx.conf /etc/nginx/nginx.conf

RUN apk add vim

# CMD [ "/bin/sh" ]
CMD /usr/sbin/nginx & /usr/sbin/sigsci-agent -config /etc/sigsci/agent.conf
