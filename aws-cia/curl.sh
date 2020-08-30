#!/bin/bash
set -eux

declare -r HOST=$HOST

wait-for-url() {
    echo "Testing $1"
    gtimeout -s TERM 20 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${0})" != "200" ]];\
    do echo "Waiting for ${0}" && sleep 2;\
    done' ${1}
    echo "OK!"
    curl -I $1
}
wait-for-url http://${HOST}