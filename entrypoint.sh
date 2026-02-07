trap shutdown TERM

fallback_crt=/etc/letsencrypt/fallback_crt.pem
fallback_key=/etc/letsencrypt/fallback_key.pem

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
        if [ ! -f /etc/letsencrypt/renewal/$i.conf ]; then
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
            echo "SSL FALLBACK $i"
            crt_path=$fallback_crt
            key_path=$fallback_key
        fi

        write_domain_ssl_conf $i $crt_path $key_path

        if [ $first == true ]; then
            cp /etc/nginx/ssl/$i.conf /etc/nginx/ssl/default.conf
            first=false
        fi
    done
}

write_domain_ssl_conf() {
    echo "ssl_certificate     $2;"  > /etc/nginx/ssl/$1.conf
    echo "ssl_certificate_key $3;" >> /etc/nginx/ssl/$1.conf
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

if [ ! -f $fallback_crt ]; then
    openssl req -x509 -newkey rsa:4096 -sha256 -days 23456 -subj / -nodes -out $fallback_crt -keyout $fallback_key
fi

mkdir -p /etc/nginx/ssl
write_domain_ssl_conf fallback $fallback_crt $fallback_key

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
