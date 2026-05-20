#!/bin/bash
set -e

# Remember where we started so we can write absolute paths regardless of `cd`s below.
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Generate a random base64 secret using the alpine/openssl image.
# Stderr is dropped because on Windows/Git Bash docker.exe can emit
# "failed to get console mode for stdout: The handle is invalid." on stdout/stderr;
# all whitespace is stripped (not just non-printable) so the file is a single clean line.
function generate_secret_value(){
  docker run --rm alpine/openssl rand -base64 32 2>/dev/null | tr -d '[:space:]'
}

function generate_secrets(){
  mkdir -p "$1"

  for secretfile in "${@:2}"
  do
    if [ ! -f "$1/$secretfile" ]; then
      secret="$(generate_secret_value)"
      if [ -z "$secret" ]; then
        echo "ERROR: failed to generate secret for $secretfile" >&2
        exit 1
      fi
      printf '%s\n' "$secret" > "$1/$secretfile"
    fi
  done
}

# Write a user-supplied password to a secret file, stripping any CR/LF/whitespace
# the terminal may have appended (important on Windows).
function write_user_password(){
  local file="$1"
  local value="$2"
  printf '%s\n' "$(printf '%s' "$value" | tr -d '[:space:]')" > "$file"
}

if [ ! -x "$(command -v docker)" ]; then
  echo "Docker must be installed"
  echo "https://docs.docker.com/install"
  exit 1
fi

if [ ! -x "$(command -v git)" ]; then
  echo "Git must be installed"
  echo "https://github.com/git-guides/install-git"
  exit 1
fi

echo "Creating data folder..."
mkdir -p "$ROOT_DIR/quantimage2-data"

echo "Cloning the required projects..."

if [ ! -d "$ROOT_DIR/quantimage2-kheops" ]; then
  echo "Cloning customized Kheops..."
  git clone https://github.com/medgift/quantimage2-kheops.git "$ROOT_DIR/quantimage2-kheops"
fi

if [ ! -d "$ROOT_DIR/quantimage2_backend" ]; then
  echo "Cloning QuantImage v2 Backend"
  git clone https://github.com/medgift/quantimage2_backend.git "$ROOT_DIR/quantimage2_backend"
fi

if [ ! -d "$ROOT_DIR/quantimage2-frontend" ]; then
  echo "Cloning QuantImage v2 Frontend"
  git clone https://github.com/medgift/quantimage2-frontend.git "$ROOT_DIR/quantimage2-frontend"
fi

secretpath="secrets"
docker pull alpine/openssl

echo "Generating secrets for kheops services (if necessary)"
cd "$ROOT_DIR/quantimage2-kheops"

kheops_secretfiles=("kheops_auth_hmasecret" "kheops_auth_hmasecret_post" \
  "kheops_client_dicomwebproxysecret" "kheops_client_zippersecret" \
  "kheops_pacsdb_pass" "kheops_authdb_pass" "kheops_auth_admin_password")

generate_secrets "$secretpath" "${kheops_secretfiles[@]}"

echo "Generating secrets for backend services (if necessary)"
cd "$ROOT_DIR/quantimage2_backend"

{
  printf '%s\n' "# Docker volumes mount directory"
  printf 'QUANTIMAGE2_DATA_MOUNT_DIRECTORY=%s\n' "$ROOT_DIR/quantimage2-data"
} > .env

backend_secretfiles=("db_root_password" "db_user_password" "keycloak_db_user_password")

generate_secrets "$secretpath" "${backend_secretfiles[@]}"

if [ ! -f "$secretpath/keycloak_admin_password" ]; then
  while [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; do
    echo "Enter a password to be set for the Keycloak administrator account"
    echo "(username will be kcadmin):"
    read -r KEYCLOAK_ADMIN_PASSWORD
  done
  write_user_password "$secretpath/keycloak_admin_password" "$KEYCLOAK_ADMIN_PASSWORD"
fi

if [ ! -f "$secretpath/quantimage2_admin_password" ]; then
  while [ -z "$QUANTIMAGE2_ADMIN_PASSWORD" ]; do
    echo "Enter a password to be set for the QuantImage v2 administrator account"
    echo "(username will be admin@quantimage2.ch):"
    read -r QUANTIMAGE2_ADMIN_PASSWORD
  done
  write_user_password "$secretpath/quantimage2_admin_password" "$QUANTIMAGE2_ADMIN_PASSWORD"
fi

echo "Creating/Starting Docker containers..."

composefiles="-f docker-compose.yml -f docker-compose.local.yml"

# Check if we are in "VM Mode", for restarting containers automatically
if [ "$VM_MODE" = "1" ]; then
  composefiles="$composefiles -f docker-compose.vm.yml"
fi

echo "Starting Kheops..."
cd "$ROOT_DIR/quantimage2-kheops"
docker compose $composefiles up -d

echo "Starting Backend..."
cd "$ROOT_DIR/quantimage2_backend"
docker compose $composefiles build
docker compose $composefiles up -d

echo "Starting Frontend..."
cd "$ROOT_DIR/quantimage2-frontend"
docker compose $composefiles build
docker compose $composefiles up -d

echo "KHEOPS will be available at        : http://localhost"
echo "QuantImage v2 will be available at : http://localhost:3000"
echo "Keycloak will be available at      : http://localhost:8081"
echo "phpMyAdmin will be available at    : http://localhost:8888"
echo "Flower will be available at        : http://localhost:3333"
echo "OHIF viewer will be available at   : http://localhost:4567"
