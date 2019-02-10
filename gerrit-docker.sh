#!/bin/bash
# Zeng Ganghui @ 2018.10.10

function help {
    echo "Usage: $0 <build|run|start> [ver]"
    exit 1
}

cmd="$1"
ver="$2"
[ -z "$cmd" ] && help

if [ "cmd" != "start" ] ; then
  [ -z $ver ] && help
fi

PROXY_IP=10.57.30.78
PROXY_PORT=8118
DOCKER_NAME=gerrit2

in_review_site="/var/gerrit/review_site"
ot_review_site="/home/admin/gerrit2/review_site"
image="registry1:8000/library/gerrit-2.15-alpine:$ver"


if [ "$cmd" = "build" ] ; then
  docker build -t $image . \
    --build-arg https_proxy=http://${PROXY_IP}:${PROXY_PORT} \
    --build-arg http_proxy=http://${PROXY_IP}:${PROXY_PORT} \
    --build-arg no_proxy=localhost,127.0.0.1,10.57..,192.168.. \
    --build-arg registry="registry1:8000/hub.docker.com/"
  exit $?
fi


if [ "$cmd" = "run" ] ; then
  docker run \
    --name $DOCKER_NAME \
    -e MIGRATE_TO_NOTEDB_OFFLINE=true \
    -e SMTP_SERVER=smtp.tongdun.cn \
    -e GERRIT_INIT_ARGS='--install-all-plugins' \
    -v $ot_review_site:$in_review_site \
    -v /etc/localtime:/etc/localtime:ro \
    -p 8080:8080 \
    -p 29418:29418 \
    -d $image
#    -it $image /bin/bash  # for debug
fi

if [ "$cmd" = "start" ] ; then
  docker start $DOCKER_NAME
fi

if [ $? == 0 ] ; then
  # add smtp hosts
  docker exec $DOCKER_NAME bash -c "sed '/smtp.tongdun/d' /etc/hosts"
  docker exec $DOCKER_NAME bash -c "echo '192.168.8.126 smtp.tongdun.cn' >> /etc/hosts"
  docker exec $DOCKER_NAME bash -c "echo '192.168.8.126 smtp.tongdun.net' >> /etc/hosts"
  echo "start gerrit docker success"
  exit 0
else
  echo "start gerrit docker failed"
  exit $?
fi

help
