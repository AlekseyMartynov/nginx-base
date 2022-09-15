FROM alpine:3.16

RUN apk add --no-cache nginx certbot

RUN sed -i 's/TLSv1\.1//g' /etc/nginx/nginx.conf

ADD http.d/*      /etc/nginx/http.d/
ADD dhparam.pem   /
ADD entrypoint.sh /

VOLUME /etc/letsencrypt
VOLUME /mnt/acme-webroot

ENV LE_EMAIL=letsencrypt@example.com
ENV LE_DOMAINS="example.com example.org"
ENV NGINX_LOGS=true

STOPSIGNAL SIGKILL
ENTRYPOINT [ "sh", "-e", "/entrypoint.sh" ]
