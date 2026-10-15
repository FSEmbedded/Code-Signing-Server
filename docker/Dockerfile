FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

###############################################################################
# These pakages include the necessary parts to build and use the signing server
###############################################################################
RUN apt-get update && apt-get install -y \
    bash \
    openssh-server \
    openssh-client \
    openssl \
    iproute2 \
    iputils-ping \
    net-tools \
    sudo \
    ca-certificates \
	bsdmainutils \
	binutils \
	libarchive-zip-perl \
    xxd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
# These are some usefull additional dev-tools, not for use on a production
# server.
###############################################################################
#RUN apt-get update && apt-get install -y \
#    vim \
#    nano \
#    less \
#    file \
#    curl \
#    wget \
#    rsync \
#    tar \
#    gzip \
#    unzip \
#    zip \
#    tree \
#    procps \

###############################################################################
# The internal infrastructure relies on users and groups there are 4 important
# users where three need to be created
# - root      for root access of an administrator, not meant for login
# - admin     admin profile for login
# - signer    profile without login, is able to use the signing tools
# - client    profile whose ssh login exposes an API to invoke signing of
#             Images
# The access rights of the Users will be handled in later commands
###############################################################################
RUN groupadd -g 2000 client && \
	useradd -u 2000 -g client -m client && \
    groupadd -g 2001 signer && \
	useradd -u 2001 -g signer -m signer && \
    usermod -aG client signer && \
    groupadd -g 2002 admin && \
    useradd -u 2002 -g admin -m admin

###############################################################################
# Manage SSH access rights.
# The most important parts are:
# - client is forced on the API script dispatch
# - only admin has tty access
###############################################################################
RUN mkdir /var/run/sshd && \
    echo '\
Match User client\n\
    ForceCommand /usr/local/bin/dispatch\n\
    DisableForwarding yes\n\
    PermitTTY no\n\
    PasswordAuthentication no\n\
Match User signer\n\
    DisableForwarding yes\n\
    PermitTTY no\n\
Match User root\n\
    DisableForwarding yes\n\
    PermitTTY no\n\
Match User admin\n\
    DisableForwarding yes\n\
' >> /etc/ssh/sshd_config && \
    mkdir -p /home/client/.ssh && \
    chmod 700 /home/client/.ssh

###############################################################################
# Bash Script containing the API of the client user. It can:
# - delete the stagng and output area
# - list all files in the output area
# - invoke signing of all files in staging
###############################################################################
COPY scripts/dispatch /usr/local/bin/dispatch

###############################################################################
# Create the ssh directories for the users public key(s), so Yocto is able to
# communicate seemless with the# server. Otherwise a password is needed. This 
# would cause Yocto to fail.
# Optional: Copy an existing public key
###############################################################################
COPY tools/id_ed25519.pub /home/client/.ssh/authorized_keys
RUN chmod 555 /usr/local/bin/dispatch && \
    chown -R client:client /home/client/.ssh && \
    chmod 600 /home/client/.ssh/authorized_keys


###############################################################################
# Create and populate the /tools/ directory This is the Heart of the container. 
# It contans the fs-secure-boot-tool, the imx-cstand a script with privileged
# commands which client is allowed to call so signer invokes the more secure
# parts of the process.
###############################################################################
COPY tools/fs-secure-boot-tool /tools/fs-secure-boot-tool/
COPY tools/imx-code-signing-tool /tools/imx-code-signing-tool/
COPY scripts/sign-and-serve.sh /tools/
RUN chown -R signer:signer /tools && \
    chmod -R 700 /tools && \
    chmod -R 700 /tools/imx-code-signing-tool/

###############################################################################
# Add interface directories, for the client to provide and retrieve files
###############################################################################
RUN mkdir /staging && chown -R client:client /staging && \
    mkdir /output && chown -R client:client /output && \
    chmod 770 /output && chmod 770 /staging

###############################################################################
# Allow client to call the sign-and-serve.sh script as signer without login.
# This script is rather short and hardcoded to specific paths because of its
# delicate tasks.
###############################################################################
RUN echo 'client ALL=(signer) NOPASSWD: /tools/sign-and-serve.sh' \
    > /etc/sudoers.d/serve && \
    chmod 440 /etc/sudoers.d/serve

###############################################################################
# For demo purposes we bind the demo server to localhost:2222
###############################################################################
EXPOSE 22

###############################################################################
# PASSWORDS MUST BE CHANGED, NOT FOR PRODUCTION OR SYSTEM CRITICAL ENVIRONMENTS
# i repeat, i repeat
# PASSWORDS MUST BE CHANGED, NOT FOR PRODUCTION OR SYSTEM CRITICAL ENVIRONMENTS
# one more for good measure
# PASSWORDS MUST BE CHANGED, NOT FOR PRODUCTION OR SYSTEM CRITICAL ENVIRONMENTS
###############################################################################
RUN echo 'root:root' | chpasswd && \ 
    echo 'admin:admin' | chpasswd && \
    echo 'signer:signer' | chpasswd

###############################################################################
# The server can be set up creating its own certificates, or copy existing
# ones. The default is creating. By commenting the active lines below and
# uncommenting the commented ones, you can change the behaviour.
###############################################################################
USER signer
RUN cd /tools/fs-secure-boot-tool/ && printf "12345678\ndo_not_use_in_production\nn\nrsa\n2048\n5\n4\ny\n" | ./makeAction.sh --action=c --cst-dir=/tools/imx-code-signing-tool/ --hab-type="ahab" --gen-type="plain"
USER root
# Copy Certificates
#USER signer
#COPY keys/* /tools/imx-code-signing-tool/keys/
#COPY crts/* /tools/imx-code-signing-tool/crts/
#RUN cd /tools/fs-secure-boot-tool/ && ./makeAction.sh --action=c --cst-dir=/tools/imx-code-signing-tool/
#USER root

###############################################################################
# At last, open the SSH interface
###############################################################################
CMD ["/usr/sbin/sshd", "-D"]
