#!/bin/sh -e

if [ ! -f dhparam.pem ]; then
    openssl dhparam -outform pem -out dhparam.pem 2048
fi

docker build -t private/nginx-base .
