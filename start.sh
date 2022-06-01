#!/bin/bash

PUFFER=""
DESIRED_SERVICE=""
ENV_VAR=""
TOP_DOMAIN=""
INSTALLED_SERVICES="\n\n"

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

  while true; do
      read -p "Do you wish to stop&kill&remove all docker services ? " yn
      case $yn in
          [Yy]* ) stop_docker ; break;;
          [Nn]* ) break;;
          * ) echo "Please answer yes or no.";;
      esac
  done

  echo "Installing mandatory: "
  sleep 1
  apt-get update
  apt-get upgrade -y
  apt-get install docker
  apt-get install docker-compose-plugin
  apt-get install sudo
  apt-get install htpasswd
  apt-get update
  apt-get upgrade -y

  echo "Creating mandatory directory"
  mkdir -p "/etc/traefik"

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

  echo -ne $INSTALLED_SERVICES
}

stop_docker () {
  docker kill $(docker ps -q)
  docker rm $(docker ps -a -q)
  docker rmi $(docker images -q)
}

container_up () {
  cd ${DESIRED_SERVICE}
  docker-compose -f docker-compose.yaml up -d
  echo "Service ${DESIRED_SERVICE} was started in the background"
  cd ..
}

edit_env_file () {
  read -p  "$1 " new_val
  sed -i "s/$ENV_VAR/${new_val}/" "./${DESIRED_SERVICE}/.env"
  PUFFER=${new_val}
}

edit_yaml_file () {
  read -p  "$1 " new_val
  sed -i "s/$ENV_VAR/$new_val/" "./${DESIRED_SERVICE}/docker-compose.yaml"
  PUFFER=${new_val}
}

edit_env_file_domain () {
  ENV_VAR="{DOMAIN}"
  read -p  "$1 " new_val
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
  echo "Creating proxy network"
  docker network create proxy

  ENV_VAR="{YOUR_EMAIL}"
  edit_yaml_file "Enter your E-Mail address for the certificates resolvers: "

  echo "Providing rights to certificates resolvers"
  sudo chmod 600 -R ./traefik/letsencrypt

  edit_env_file_domain "Please provide the desired main domain. The service will run under traefik.YOUR_INPUT: "

  ENV_VAR="{DASHBOARD_USER_PASS}"
  echo "Please provide a username and password for the traefik panel. "
  read -p  "User: " new_val_user
  read -p  "Password: " new_val
  htpasswd -b -c /etc/traefik/userfile "${new_val_user}" "${new_val}"

  install_default

  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:${DESIRED_SERVICE}.${TOP_DOMAIN}\nUser: ${new_val_user}\nPassword: ${new_val}\n\n"
}

install_teamspeak () {
  ENV_VAR="{TS3SERVER_DB_PASS}"
  edit_env_file "Please provide a secure database password: "

  install_default

  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service Teamspeak\nURL:ts.${TOP_DOMAIN}\n\n"
}

install_seafile () {
  ENV_VAR="{SEAFILE_ADMIN_MAIL}"
  edit_env_file "Please provide your seafile admin mail: "
  email=${PUFFER}

  ENV_VAR="{SEAFILE_ADMIN_PASSWORD}"
  edit_env_file "Please provide your seafile admin password: "
  pass=${PUFFER}

  install_default

  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:${DESIRED_SERVICE}.${TOP_DOMAIN}\nE-Mail: ${email}\nPassword: ${pass}\n\n"
}

install_resilio-sync () {
  install_default
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:resilio.${TOP_DOMAIN}\n\n"
}

install_portainer () {
  install_default
  echo "In order to prevent any upcoming portainer needs to be restarted. This could take up to 20s"
  sleep 5
  docker restart portainer
  sleep 1
  echo "Portainer was restarted"

  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:${DESIRED_SERVICE}.${TOP_DOMAIN}\nYOU MUST VISIT THE URL TO CREATE AN ADMIN USER\n\n"
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
  pass=${PUFFER}

  install_default
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:${DESIRED_SERVICE}.${TOP_DOMAIN}\nUser: admin\nPassword: ${pass}\n\n"
}

install_jenkins () {
  CURRENT_DIR="$( pwd; )"
  sed -i "s/{YOUR_SOURCE_FOLDER}/$CURRENT_DIR/" "./jenkins/docker-compose.yaml"
  sed -i "s/{YOUR_SOURCE_FOLDER_2}/$CURRENT_DIR/" "./jenkins/docker-compose.yaml"

  install_default
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:${DESIRED_SERVICE}.${TOP_DOMAIN}\nYOU MUST VISIT THE URL TO FINISH INSTALLATION\n\n"
}

install_homer () {
  install_default

  I_AM_TIRED_AND_THAT_IS_WHY_THIS_IS_DONE="DIRTY"

  cp -r ./${DESIRED_SERVICE}/assets ./${DESIRED_SERVICE}/data
  mv ./${DESIRED_SERVICE}/assets ./${DESIRED_SERVICE}/data/assets
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:${TOP_DOMAIN}\nSee Username and Password at traefik\n\n"
}

install_gitlab () {
  ENV_VAR="{ROOT_PASSWORD}"
  edit_env_file "Please an initial alphanumeric root password: "
  pass=${PUFFER}

  ENV_VAR="{SMTP_PASSWORD}"
  edit_env_file "Please provide a secure SMTP password: "

  DESIRED_SERVICE="Gitlab-AWS-S3-Backup"
  input_installer
  DESIRED_SERVICE="gitlab"


  install_default
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:git.${TOP_DOMAIN}\nUser: root\nPassword: ${pass}\n\n"

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

  ENV_VAR="{AWS_UPLOAD_REMOTE_DIR}"
  edit_env_file "Please provide aws upload directory: "

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
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service Wordpress\nURL:wp.${TOP_DOMAIN}\nYOU MUST VISIT THE URL TO FINISH INSTALLATION\n\n"
}

install_matrix () {
  sed -i "s/{DOMAIN}/${DOMAIN}/" "./${DESIRED_SERVICE}/element-config.json"
  sed -i "s/{DOMAIN_2}/${DOMAIN}/" "./${DESIRED_SERVICE}/element-config.json"

  ENV_VAR="{POSTGRES_PW}"
  edit_env_file "Please provide a secure database password: "

  docker run -it --rm \
      -v "$( pwd; )/synapse:/data" \
      -e SYNAPSE_SERVER_NAME=matrix."${DOMAIN}" \
      -e SYNAPSE_REPORT_STATS=yes \
      matrixdotorg/synapse:latest generate

  install_default
  INSTALLED_SERVICES="${INSTALLED_SERVICES}Service ${DESIRED_SERVICE}\nURL:matrix.${TOP_DOMAIN}\nI AM SORRY IF YOU RLY TRIED IT, BUT IT IS CURRENTLY BROKEN. But feel free to contribute and fix it \n\n"
}

entry