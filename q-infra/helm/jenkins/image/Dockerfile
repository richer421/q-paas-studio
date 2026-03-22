ARG JENKINS_IMAGE=jenkins/jenkins:lts-jdk17
ARG DOCKER_CLI_IMAGE=docker:29.1.3-cli

FROM ${DOCKER_CLI_IMAGE} AS docker-cli

FROM ${JENKINS_IMAGE}

USER root

RUN apt-get update \
    && apt-get install -y --fix-missing --no-install-recommends make golang-go \
    && rm -rf /var/lib/apt/lists/*

COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker

USER jenkins

ENV JENKINS_UC_DOWNLOAD=https://mirror.twds.com.tw/jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
