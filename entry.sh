#!/bin/bash

echo '{"irods_host": "data.cyverse.org", "irods_port": 1247, "irods_user_name": "$IPLANT_USER", "irods_zone_name": "iplant"}' | envsubst > $HOME/.irods/irods_environment.json

if [ -f "/home/workspace/data-store/home/$IPLANT_USER/.gitconfig" ]; then
  cp /home/workspace/data-store/home/$IPLANT_USER/.gitconfig /home/workspace/
fi

exec ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --host 0.0.0.0 --without-connection-token "${@}" --