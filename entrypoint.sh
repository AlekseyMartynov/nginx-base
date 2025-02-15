trap shutdown TERM
trap 'exit 1' QUIT

shutdown() {
    if [ -f /run/nginx/nginx.pid ]; then
        NGINX_PID=$(cat /run/nginx/nginx.pid)
        kill $NGINX_PID
        wait $NGINX_PID
    fi
    exit 0
}

certbot_renew() {
    certbot certonly -n --agree-tos --keep --expand --webroot -w /mnt/acme-webroot -m $LE_EMAIL $LE_DOMAIN_ARGS

    if [ "$LE_RENEW_ALL" = "true" ]; then
        certbot renew -n
    fi

    ensure_ssl_config
    nginx -s reload
}

ensure_ssl_config() {
    # https://serverfault.com/a/1104847
    chown -R :le_readers /etc/letsencrypt/archive /etc/letsencrypt/live
    chmod -R g+r         /etc/letsencrypt/archive /etc/letsencrypt/live
    chmod    g+x         /etc/letsencrypt/archive /etc/letsencrypt/live

    if [ -f /etc/letsencrypt/live/$LE_MAIN_DOMAIN/fullchain.pem ]; then
        if [ -f /etc/nginx/http.d/_cert.conf ]; then
            echo "SSL config already active"
        else
            echo "ssl_certificate     /etc/letsencrypt/live/$LE_MAIN_DOMAIN/fullchain.pem;" > /etc/nginx/http.d/_cert.conf
            echo "ssl_certificate_key /etc/letsencrypt/live/$LE_MAIN_DOMAIN/privkey.pem;"  >> /etc/nginx/http.d/_cert.conf
            cp /etc/nginx/http.d.ssl/* /etc/nginx/http.d
            echo "SSL config activated"
        fi
    else
        echo "SSL config SKIPPED"
    fi
}

for i in $LE_DOMAINS; do
    [ -z "$LE_MAIN_DOMAIN" ] && LE_MAIN_DOMAIN=$i
    LE_DOMAIN_ARGS="$LE_DOMAIN_ARGS -d $i"
done

if [ "$NGINX_LOGS" == true ]; then
    # https://serverfault.com/a/932888
    ln -sf /proc/1/fd/1 /var/log/nginx/access.log
    ln -sf /proc/1/fd/2 /var/log/nginx/error.log
else
    ln -sf /dev/null /var/log/nginx/access.log
    ln -sf /dev/null /var/log/nginx/error.log
fi

rm -f /run/nginx/nginx.pid

getent group le_readers || addgroup -g $LE_READERS_GID le_readers
adduser nginx le_readers

ensure_ssl_config

if [ "$NGINX_TEST" == true ]; then
    nginx -t
    exit $?
fi

nginx
certbot_renew

sh /monitor.sh &

while true; do
    sleep 43200 & wait $!
    certbot_renew
done
