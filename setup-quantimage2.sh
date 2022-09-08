#!/bin/bash

function generate_secrets(){
  if [ ! -d "$1" ]
  then
    mkdir $1
  fi

  for secretfile in "${@:2}"
  do
    if [ ! -f "$secretpath/$secretfile" ]; then
      printf "%s\n" $(docker run --rm alpine/openssl rand -base64 32 | tr -dc '[:print:]') > $secretpath/$secretfile
    fi
  done
}

if [ ! -x "$(command -v docker)" ];
then
  echo "Docker must be installed"
  echo "https://docs.docker.com/install"
  exit 1
fi

if [ ! -x "$(command -v git)" ];
then
  echo "Git must be installed"
  echo "https://github.com/git-guides/install-git"
  exit 1
fi

echo "Cloning the required projects..."

echo "Cloning customized Kheops..."
git clone https://github.com/medgift/quantimage2-kheops.git

echo "Cloning QuantImage v2 Backend"
git clone https://github.com/medgift/quantimage2_backend.git

echo "Cloning QuantImage v2 Frontend"
git clone https://github.com/medgift/quantimage2-frontend.git

secretpath="secrets"
docker pull alpine/openssl

echo "Generating secrets for kheops services (if necessary)"
cd quantimage2-kheops

secretfiles=("kheops_auth_hmasecret" "kheops_auth_hmasecret_post" \
  "kheops_client_dicomwebproxysecret" "kheops_client_zippersecret" \
  "kheops_pacsdb_pass" "kheops_authdb_pass" "kheops_auth_admin_password")

generate_secrets ${secretpath} ${secretfiles[*]}

echo "Generating secrets for backend services (if necessary)"
cd ../quantimage2_backend

secretfiles=("db_root_password" "db_user_password" "keycloak_db_user_password")

generate_secrets ${secretpath} ${secretfiles[*]}

if [ ! -f "$secretpath/keycloak_admin_password" ]; then
  while [ -z $KEYCLOAK_ADMIN_PASSWORD ]
  do
    echo "Enter a password to be set for the Keycloak administrator account"
    echo "(username will be kcadmin):"
    read KEYCLOAK_ADMIN_PASSWORD
  done

  printf "%s\n" $(printf "%s" $KEYCLOAK_ADMIN_PASSWORD | tr -dc '[:print:]') > $secretpath/keycloak_admin_password
fi

if [ ! -f "$secretpath/quantimage2_admin_password" ]; then
  while [ -z $QUANTIMAGE2_ADMIN_PASSWORD ]
  do
    echo "Enter a password to be set for the QuantImage v2 administrator account"
    echo "(username will be admin@quantimage2.ch):"
    read QUANTIMAGE2_ADMIN_PASSWORD
  done

  printf "%s\n" $(printf "%s" $QUANTIMAGE2_ADMIN_PASSWORD | tr -dc '[:print:]') > $secretpath/quantimage2_admin_password
fi

echo "Creating/Starting Docker containers..."

composefiles="-f docker-compose.yml -f docker-compose.local.yml"

# Check if we are in "VM Mode", for restarting containers automatically
if [ "$VM_MODE" = "1" ]; then
  composefiles="$composefiles -f docker-compose.vm.yml"
fi

echo "Starting Kheops..."
cd ../quantimage2-kheops
docker compose $composefiles up -d

echo "Starting Backend..."
cd ../quantimage2_backend
docker compose $composefiles build
docker compose $composefiles up -d

echo "Starting Frontend..."
cd ../quantimage2-frontend
docker compose $composefiles build
docker compose $composefiles up -d

echo "KHEOPS will be available at        : http://localhost"
echo "QuantImage v2 will be available at : http://localhost:3000"
echo "Keycloak will be available at      : http://localhost:8081"
echo "phpMyAdmin will be available at    : http://localhost:8888"
echo "Flower will be available at        : http://localhost:3333"
echo "OHIF viewer will be available at   : http://localhost:4567"