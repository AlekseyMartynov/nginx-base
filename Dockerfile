FROM alpine:3.11

RUN apk add --no-cache nginx certbot

ADD conf.d/*      /etc/nginx/conf.d/
ADD dhparam.pem   /
ADD entrypoint.sh /

VOLUME /etc/letsencrypt
VOLUME /mnt/acme-webroot

ENV LE_EMAIL=letsencrypt@example.com
ENV LE_DOMAINS="example.com example.org"
ENV NGINX_LOGS=true

STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "-e", "/entrypoint.sh" ]
