#!/bin/bash

GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_ACCESS_TOKEN=$GH_ACCESS_TOKEN

echo -e "Github Repo owner: $GH_OWNER"

REG_TOKEN=$(curl -sX POST -H "Authorization: token ${GH_ACCESS_TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh --url https://github.com/${GH_OWNER}/${GH_REPOSITORY} --token ${REG_TOKEN}

docker context create outsider --docker "host=ssh://dockerhost"
docker context use outsider

echo -e "Generating a key pair for the container to ssh into the host..."
mkdir -p /home/docker/.ssh/keys/
ssh-keygen -q -t ed25519 -f /home/docker/.ssh/keys/docker2host
echo -e ""
echo -e "Successfully generated a key pair"

# ssh-copy-id -i /home/docker/.ssh/keys/docker2host dockerhost

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!