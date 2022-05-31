#!/bin/bash

DESIRED_SERVICE=""
ENV_VAR=""
TOP_DOMAIN=""

entry () {
  if [ "$( pwd; )" = "/tmp" ]
  then
    echo "Please do run this script inside its directory "
    sleep 3
    exit
  fi

  echo "Following services are not able to be installed via this script: "
  echo "openvpn"
  echo "nextcloud-backups"
  echo "Incomplete element/matrix"
  sleep 2

  echo "Installing mandatory: "
  apt-get install docker
  apt-get install sudo
  apt-get install openssl

  echo "In the following this script will install all desired services you want:"
  echo

  DESIRED_SERVICE="traefik"
  input_installer

  DESIRED_SERVICE="teamspeak"
  input_installer

  DESIRED_SERVICE="seafile"
  input_installer

  DESIRED_SERVICE="resilio-sync"
  input_installer

  DESIRED_SERVICE="portainer"
  input_installer

  DESIRED_SERVICE="nextcloud"
  input_installer

  DESIRED_SERVICE="jenkins"
  input_installer

  DESIRED_SERVICE="homer"
  input_installer

  DESIRED_SERVICE="gitlab"
  input_installer

  DESIRED_SERVICE="blog"
  input_installer

  DESIRED_SERVICE="matrix"
  input_installer
}

container_up () {
    docker-compose -f ./${DESIRED_SERVICE}/docker-compose.yaml up -d
    echo "Service ${DESIRED_SERVICE} was started in the background"
}

edit_env_file () {
    read -p  "$1 " new_val
    sed -i "s/$ENV_VAR/$new_val/" "./${DESIRED_SERVICE}/.env"
}

edit_env_file_domain () {
  ENV_VAR="{DOMAIN}"
  read -p  " " new_val
  sed -i "s/$ENV_VAR/$new_val/" "./${DESIRED_SERVICE}/.env"
  TOP_DOMAIN=$new_val
}

edit_env_file_sub_domain () {
  sed -i "s/{DOMAIN}/$TOP_DOMAIN/" "./${DESIRED_SERVICE}/.env"
}

check_mandatory () {
  if [ ${DESIRED_SERVICE} = "traefik" ]
  then
    echo "traefik is mandatory! Script will exit"
    sleep 3
    exit
  fi
  if [ ${DESIRED_SERVICE} = "Gitlab-AWS-S3-Backup" ]
    then
      mv ./gitlab/docker-compose-no-s3.yaml ./gitlab/docker-compose.yaml
    fi
  echo "${DESIRED_SERVICE} will be skipped"
}

input_installer () {
  while true; do
      read -p "Do you wish to install ${DESIRED_SERVICE} ? " yn
      case $yn in
          [Yy]* ) install_${DESIRED_SERVICE} ; break;;
          [Nn]* ) check_mandatory ; break;;
          * ) echo "Please answer yes or no.";;
      esac
  done
}

install_default () {
    edit_env_file_sub_domain
    container_up
}

install_traefik () {
  input_installer
  echo "Creating proxy network"
  docker network create proxy

  read -p  "Enter your E-Mail address for the certificates resolvers: " email
  sed -i "s/{YOUR_EMAIL}/$email/" "./traefik/docker-compose.yaml"

  echo "Providing rights to certificates resolvers"
  sudo chmod 600 -R ./traefik/letsencrypt

  echo "Please provide the desired main domain. The service will run under traefik.YOUR_INPUT"
  edit_env_file_domain

  ENV_VAR="DASHBOARD_USER"
  echo "Please provide a username and password for the traefik panel. "
  edit_env_file "Username: "

  ENV_VAR="DASHBOARD_PASSWORD"
  read -p  "Password: " new_val
  DASHBOARD_PASS=$(openssl passwd -crypt "${new_val}")
  sed -i "s/$ENV_VAR/$DASHBOARD_PASS/" "./${DESIRED_SERVICE}/.env"

  container_up
}

install_teamspeak () {
  ENV_VAR="{TS3SERVER_DB_PASS}"
  edit_env_file "Please provide a secure database password: "

  container_up
}

install_seafile () {
  ENV_VAR="{SEAFILE_ADMIN_MAIL}"
  edit_env_file "Please provide your seafile admin mail: "

  ENV_VAR="{SEAFILE_ADMIN_PASSWORD}"
  edit_env_file "Please provide your seafile admin password: "

  install_default
}

install_resilio-sync () {
  install_default
}

install_portainer () {
  install_default
}

install_nextcloud () {
  ENV_VAR="{POSTGRES_PW}"
  read -p  "Please provide a secure database password: " new_val
  sed -i "s/$ENV_VAR/$new_val/" "./${DESIRED_SERVICE}/.env"
  ENV_VAR="{POSTGRES2_PW}"
  sed -i "s/$ENV_VAR/$new_val/" "./${DESIRED_SERVICE}/.env"

  ENV_VAR="{REDIS_PW}"
  edit_env_file "Please provide a secure redis password: "

  ENV_VAR="{NEXTCLOUD_PASS}"
  edit_env_file "Please provide a secure admin password: "

  install_default
}

install_jenkins () {
  sed -i "s/{YOUR_SOURCE_FOLDER}/$( pwd; )/" "./jenkins/docker-compose.yaml"
  sed -i "s/{YOUR_SOURCE_FOLDER_2}/$( pwd; )/" "./jenkins/docker-compose.yaml"

  install_default
}

install_homer () {
    ENV_VAR="{DASHBOARD_PASSWORD}"
    read -p  "Please provide a dashboard password: " new_val
    DASHBOARD_PASS=$(openssl passwd -crypt "${new_val}")
    sed -i "s/$ENV_VAR/$DASHBOARD_PASS/" "./${DESIRED_SERVICE}/.env"

    install_default

    I_AM_TIRED_AND_THAT_IS_WHY_THIS_IS_DONE="DIRTY"

    cp -r ./${DESIRED_SERVICE}/assets ./${DESIRED_SERVICE}/data
    mv ./${DESIRED_SERVICE}/assets ./${DESIRED_SERVICE}/data/assets
}

install_gitlab () {
  ENV_VAR="{SMTP_PASSWORD}"
  edit_env_file "Please provide a secure SMTP password: "

  DESIRED_SERVICE="Gitlab-AWS-S3-Backup"
  input_installer
  DESIRED_SERVICE="gitlab"


  install_default
  echo "IN ORDER TO CREATE A GITLAB RUNNER, FOLLOW THE REDME INSTRUCTIONS IN ./gitlab/"
  sleep 2
}

install_Gitlab-AWS-S3-Backup () {
    DESIRED_SERVICE="gitlab"

    ENV_VAR="{AWS_REGION}"
    edit_env_file "Please provide your aws-region (e.g. eu-central-1): "

    ENV_VAR="{AWS_ACCESS_KEY_ID}"
    edit_env_file "Please provide your secret access key ID (starting with AKIA...): "

    ENV_VAR="{AWS_SECRET_ACCESS_KEY}"
    edit_env_file "Please provide your secret access key: "

    mv ./gitlab/docker-compose-s3.yaml ./gitlab/docker-compose.yaml
}

install_blog () {
    ENV_VAR="{MYSQL_ROOT_PASSWORD}"
    edit_env_file "Please provide a secure root database password: "

    ENV_VAR="{MYSQL_USER}"
    edit_env_file "Please provide a database user: "

    ENV_VAR="{MYSQL_PASSWORD}"
    edit_env_file "Please provide a secure database password: "

    install_default
}

install_matrix () {
  sed -i "s/{DOMAIN_2}/${DOMAIN}/" "./${DESIRED_SERVICE}/element-config.json"
  sed -i "s/{DOMAIN_2}/${DOMAIN}/" "./${DESIRED_SERVICE}/element-config.json"

  ENV_VAR="{POSTGRES_PW}"
  edit_env_file "Please provide a secure database password: "

  docker run -it --rm \
      -v "$( pwd; )/synapse:/data" \
      -e SYNAPSE_SERVER_NAME=matrix."${DOMAIN}" \
      -e SYNAPSE_REPORT_STATS=yes \
      matrixdotorg/synapse:latest generate

  install_default
}

entry