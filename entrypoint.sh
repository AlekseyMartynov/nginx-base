certbot_renew() {
    if certbot certonly -n --agree-tos --no-self-upgrade --keep --expand --webroot -w /mnt/acme-webroot -m $LE_EMAIL $LE_DOMAIN_ARGS; then
        nginx -s reload
    else
        echo "Renewal failed!"
    fi
}

try_load_ssl_config() {
    if [ -f /etc/letsencrypt/live/$LE_MAIN_DOMAIN/fullchain.pem ]; then
        echo "ssl_certificate     /etc/letsencrypt/live/$LE_MAIN_DOMAIN/fullchain.pem;" > /etc/nginx/http.d/_cert.conf
        echo "ssl_certificate_key /etc/letsencrypt/live/$LE_MAIN_DOMAIN/privkey.pem;"  >> /etc/nginx/http.d/_cert.conf
        cp /etc/nginx/http.d.ssl/* /etc/nginx/http.d
        pidof nginx && nginx -s reload
        echo "SSL config loaded"
    else
        echo "SSL config SKIPPED"
    fi
}

for i in $LE_DOMAINS; do
    [ -z "$LE_MAIN_DOMAIN" ] && LE_MAIN_DOMAIN=$i
    LE_DOMAIN_ARGS="$LE_DOMAIN_ARGS -d $i"
done

if [ "$NGINX_LOGS" == true ]; then
    ln -sf /dev/stdout /var/log/nginx/access.log
    ln -sf /dev/stderr /var/log/nginx/error.log
else
    ln -sf /dev/null /var/log/nginx/access.log
    ln -sf /dev/null /var/log/nginx/error.log
fi

mkdir -p /run/nginx

if [ "$NGINX_TEST" == true ]; then
    try_load_ssl_config
    nginx -t
    exit $?
fi

nginx -g 'daemon off;' &
certbot_renew

try_load_ssl_config

while true; do
    sleep 43200
    certbot_renew
done
