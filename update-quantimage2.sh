#!/usr/bin/env bash

echo "Updating QuantImage v2 to latest version"

composefiles="-f docker-compose.yml -f docker-compose.local.yml"

# Check if we are in "VM Mode", for restarting containers automatically
if [ "$VM_MODE" = "1" ]; then
  composefiles="$composefiles -f docker-compose.vm.yml"
fi

# Backend
cd quantimage2_backend
git reset --hard HEAD
git pull
docker compose $composefiles build
docker compose $composefiles up -d

cd ..

# Frontend
cd quantimage2-frontend
git reset --hard HEAD
git pull
docker compose $composefiles build
docker compose $composefiles up -d