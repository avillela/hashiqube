#!/bin/bash
# https://www.waypointproject.io/docs/getting-started
# https://learn.hashicorp.com/tutorials/waypoint/get-started-nomad?in=waypoint/get-started-nomad

function waypoint-install() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install curl unzip jq
  # check if waypoint is installed, start and exit
  if [ -f /usr/local/bin/waypoint ]; then
    echo -e '\e[38;5;198m'"++++ Waypoint already installed at /usr/local/bin/waypoint"
    echo -e '\e[38;5;198m'"++++ `/usr/local/bin/waypoint version`"
  else
  # if waypoint is not installed, download and install
    echo -e '\e[38;5;198m'"++++ Waypoint not installed, installing.."
    LATEST_URL=$(curl -sL https://releases.hashicorp.com/waypoint/index.json | jq -r '.versions[].builds[].url' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | egrep -v 'rc|beta' | egrep 'linux.*amd64' | sort -V | tail -n 1)
    wget -q $LATEST_URL -O /tmp/waypoint.zip
    mkdir -p /usr/local/bin
    (cd /usr/local/bin && unzip /tmp/waypoint.zip)
    echo -e '\e[38;5;198m'"++++ Installed `/usr/local/bin/waypoint version`"
  fi

  echo -e '\e[38;5;198m'"++++ Waypoint Server starting"
  export NOMAD_ADDR='http://localhost:4646'
  waypoint install -platform=nomad -nomad-dc=dc1 -accept-tos -nomad-host-volume="mysql"
  waypoint server bootstrap -server-addr=${VAGRANT_IP}:9701 -server-tls-skip-verify
  nomad status

  echo -e '\e[38;5;198m'"++++ Waypoint Server https://${VAGRANT_IP}:9702 and enter the following Token displayed below"
  export WAYPOINT_USER_TOKEN=$(waypoint user token)
  echo $WAYPOINT_USER_TOKEN
  echo $WAYPOINT_USER_TOKEN > /vagrant/hashicorp/waypoint/waypoint_user_token.txt
  waypoint context verify
  echo -e '\e[38;5;198m'"++++ Nomad http://localhost:4646"

}

waypoint-install
