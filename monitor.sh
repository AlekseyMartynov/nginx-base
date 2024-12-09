while true; do
    sleep 15

    if ! nc -z 127.0.0.1 80; then
        # https://unix.stackexchange.com/a/251267
        kill -QUIT 1
    fi
done
