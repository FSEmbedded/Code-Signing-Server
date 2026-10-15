#!/bin/bash

###############################################################################
# this script must at least be run under the signer user. It can be called with
# sudo -u signer by the client user without authentication. It is the only
# privileged task the client can invoke.
###############################################################################

cd /tools/fs-secure-boot-tool/
./makeAction.sh --cpu=${1} --action=s --image-path=/staging/${2} --cst-dir=/tools/imx-code-signing-tool/
mv bin/* /output/
chown signer:client /output/*
chmod 660 /output/*
