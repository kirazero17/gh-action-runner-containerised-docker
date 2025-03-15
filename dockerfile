# base
FROM docker.io/library/ubuntu:22.04

# Arguments
# set the github runner version
ARG RUNNER_VERSION
ARG KUBE_VERSION
ARG DOCKER_HOST
ARG ARCH
ARG PLATFORM=$(uname -s)_$ARCH
ENV DEBIAN_FRONTEND=noninteractive

# Update the system
RUN apt update -y && apt upgrade -y && useradd -m docker

# Install base apt packages
RUN apt install -y --no-install-recommends \
    curl wget jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip unzip openssh-client

# Prepare the base runner dependencies
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && cd /home/docker/actions-runner \
    && tar -xvf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm -f /actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && /home/docker/actions-runner/bin/installdependencies.sh

# Install AWS-CLI
RUN cd /home/docker \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -f ./awscli-exe-linux-x86_64.zip \
    && rm -rf ./aws

# Install docker
RUN apt install -y docker.io

# Install docker buildx
RUN wget https://github.com/docker/buildx/releases/download/v0.21.1/buildx-v0.21.1.linux-amd64 -O /home/docker/docker-buildx \
    && chmod +x /home/docker/docker-buildx \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && mv /home/docker/docker-buildx /usr/local/lib/docker/cli-plugins/docker-buildx

# Install kubectl
RUN cd /home/docker \
    && curl -LO "https://dl.k8s.io/release/v${KUBE_VERSION}/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm /home/docker/kubectl

# SSH config - you can edit the file
COPY ./ssh/config /home/docker/config
RUN mkdir -p /home/docker/.ssh/ \
    && cat /home/docker/config >> /home/docker/.ssh/config \
    && cat /home/docker/config >> /etc/ssh/ssh_config \
    && rm /home/docker/config

# SSH key
RUN ssh-keyscan ${DOCKER_HOST} >> /home/docker/.ssh/known_hosts

# Finishing
COPY start.sh start.sh
RUN chmod +x ./start.sh
RUN chown -R docker ~docker

USER docker

ENTRYPOINT ["./start.sh"]