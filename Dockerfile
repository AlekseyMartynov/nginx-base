FROM alpine:3.20

RUN apk add --no-cache nginx certbot

ADD http.d/*      /etc/nginx/http.d/
ADD ssl/*         /etc/nginx/ssl/
ADD entrypoint.sh /

VOLUME /etc/letsencrypt
VOLUME /mnt/acme-webroot

ENV LE_EMAIL=letsencrypt@example.com
ENV LE_DOMAINS="example.com example.org"
ENV NGINX_LOGS=true

ENTRYPOINT [ "sh", "/entrypoint.sh" ]
