#!/usr/bin/env bash

set -eu -o pipefail

if [ ! -d ".git" ]; then
    git init
fi

{
    echo "*.tfvars"
    echo ".env"
    echo ".terraform"
    echo "*.tfstate"
    echo "*tfstate*"
    echo "tfplan"
    echo "*tfplan*"

} > .gitignore

mkdir -p infra/envs/dev
cd infra/envs/dev
touch main.tf variables.tf versions.tf \
    outputs.tf providers.tf dev.aut.tfvars
cd ..
mkdir -p infra/modules/compute
mkdir -p infra/modules/security_group


