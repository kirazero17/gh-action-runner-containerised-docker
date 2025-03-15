#!/bin/bash

IMG_NAME="customdockerrunner"
IMG_TAG="latest"

if [[ ! -z "$(docker image ls | grep "${IMG_NAME}" | grep "${IMG_TAG}")" ]]
then
    docker rmi $IMG_NAME:$IMG_TAG -f
else
    echo -e "Image $IMG_NAME:$IMG_TAG not present in the registry. Not deleting."
fi

docker compose -f ./docker-compose-build.yaml up