trap shutdown TERM

shutdown() {
    if [ -f /run/nginx/nginx.pid ]; then
        NGINX_PID=$(cat /run/nginx/nginx.pid)
        kill $NGINX_PID
        wait $NGINX_PID
    fi
    exit 0
}

certbot_renew() {
    for i in $LE_DOMAINS; do
        if [ $i != localhost ] && [ ! -f /etc/letsencrypt/renewal/$i.conf ]; then
            certbot certonly -n --agree-tos --keep --webroot -w /mnt/acme-webroot -m $LE_EMAIL -d $i
        fi
    done

    certbot renew -n

    update_ssl_config
    nginx -s reload
}

update_ssl_config() {
    local first=true
    local crt_path
    local key_path

    for i in $LE_DOMAINS; do
        crt_path=/etc/letsencrypt/live/$i/fullchain.pem
        key_path=/etc/letsencrypt/live/$i/privkey.pem

        if [ -f $crt_path ] && [ -f $key_path ]; then
            echo "SSL OK $i"
        else
            echo "SSL MISSING $i"
            crt_path=ssl/localhost_crt.pem
            key_path=ssl/localhost_key.pem
        fi

        echo "ssl_certificate     $crt_path;"  > /etc/nginx/ssl/$i.conf
        echo "ssl_certificate_key $key_path;" >> /etc/nginx/ssl/$i.conf

        if [ $first == true ]; then
            cp /etc/nginx/ssl/$i.conf /etc/nginx/ssl/default.conf
            first=false
        fi
    done
}

if [ "$NGINX_LOGS" == true ]; then
    # https://serverfault.com/a/932888
    ln -sf /proc/1/fd/1 /var/log/nginx/access.log
    ln -sf /proc/1/fd/2 /var/log/nginx/error.log
else
    ln -sf /dev/null /var/log/nginx/access.log
    ln -sf /dev/null /var/log/nginx/error.log
fi

if [ -d /etc/nginx/http.d.ssl ]; then
    echo "Incompatible old config detected"
    exit 1
fi

rm -f /run/nginx/nginx.pid

update_ssl_config


if [ "$NGINX_TEST" == true ]; then
    nginx -t
    exit $?
fi

nginx
certbot_renew

while true; do
    for i in $(seq 2880); do
        sleep 15 & wait $!
        nc -z 127.0.0.1 80 || exit 1
    done
    certbot_renew
done
