FROM alpine:3.20

RUN apk add --no-cache nginx certbot

ADD http.d/* /etc/nginx/http.d/
ADD dhparam.pem entrypoint.sh /

VOLUME /etc/letsencrypt
VOLUME /mnt/acme-webroot

ENV LE_EMAIL=letsencrypt@example.com \
    LE_DOMAINS="example.com example.org" \
    NGINX_LOGS=true

STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "-e", "/entrypoint.sh" ]
