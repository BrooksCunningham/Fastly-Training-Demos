FROM haproxytech/haproxy-ubuntu:2.9

#### https://docs.fastly.com/en/ngwaf/installing-the-agent-on-ubuntu
# 
RUN apt-get update
RUN apt-get install -y apt-transport-https wget gnupg
RUN wget -qO - https://apt.signalsciences.net/release/gpgkey | gpg --dearmor -o /usr/share/keyrings/sigsci.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/sigsci.gpg] https://apt.signalsciences.net/release/ubuntu/ jammy main" | tee /etc/apt/sources.list.d/sigsci-release.list
RUN apt-get update

RUN apt-get install sigsci-module-haproxy

RUN sed "-i.`date +%F`" -e '$r/opt/signalsciences/haproxy-spoe/backend.txt' /etc/haproxy/haproxy.cfg
RUN sed -i -e '/^\s*frontend/r/opt/signalsciences/haproxy-spoe/frontend-2.2.txt' /etc/haproxy/haproxy.cfg

# CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]

# CMD [ "/bin/sh" ]