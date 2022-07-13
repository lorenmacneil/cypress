# Used both aws-codebuild-docker-images:5.0 & cypress/included:10.2.0 to construct this example
# https://github.com/aws/aws-codebuild-docker-images/blob/master/ubuntu/standard/5.0/Dockerfile
# https://hub.docker.com/layers/included/cypress/included/10.2.0/images/sha256-5898e749826afe75cc3d017e24cb7220330b28011aa5e490534b47dede335824?context=explore

FROM public.ecr.aws/ubuntu/ubuntu:20.04 AS core

ARG DEBIAN_FRONTEND="noninteractive"

# Update & Install curl, sudo, wget
RUN apt-get update
RUN apt-get install -y --no-install-recommends curl sudo wget

# Install Browser required tools
RUN apt-get install -y --no-install-recommends gnupg lsb-release software-properties-common

# Install Cypress required tools
RUN apt-get install -y --no-install-recommends xvfb

# Install Node
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -  \
    && sudo apt-get install -y nodejs \
    && node -v \
    && npm -v

# Install Firefox
RUN set -ex \
    && apt-add-repository -y "deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner" \
    && apt-get install -y firefox \
    && firefox --version

# Install Chrome
RUN set -ex \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && google-chrome --version

# Cleanup
RUN rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* && apt-get clean

# Set Variables
ENV USER=docker
ENV GROUP=root
ARG UID=1000
ENV CI=1 QT_X11_NO_MITSHM=1 _X11_NO_MITSHM=1 _MITSHM=0 CYPRESS_CACHE_FOLDER=~/$USER/cache/Cypress

# Add user
RUN useradd -rm -d /home/$USER -s /bin/bash -g $GROUP -G sudo -u $UID $USER

# Change owner of files
RUN sudo chown -R "${USER}:${GROUP}" /usr/lib/node_modules /usr/bin

# Switch to new user account
USER $USER
WORKDIR /home/$USER

# Install Cypress
RUN npm install -g "cypress@10.2.0" && cypress verify \
    && cypress cache path \
    && cypress cache list \
    && cypress info \
    && cypress version

ENTRYPOINT ["cypress", "run"]
