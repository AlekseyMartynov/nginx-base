#!/bin/sh -e

if [ ! -f ssl/localhost_crt.pem ]; then
    mkdir -p ssl
    openssl req -x509 -newkey rsa:4096 -sha256 -days 23456 -subj /CN=localhost -nodes -keyout ssl/localhost_key.pem -out ssl/localhost_crt.pem
fi

docker build -t private/nginx-base .
