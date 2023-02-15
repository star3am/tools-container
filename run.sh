#!/bin/bash

arch=$(uname -m)
if [[ $arch == x86_64* ]]; then
  ARCH="amd64"
elif  [[ $arch == arm64 ]]; then
  ARCH="arm64"
fi
echo "CPU is ${ARCH}"
pwd
docker rmi -f terraform-module_tools
ARCH=${ARCH} docker-compose run --rm tools bash -c '
  cd /app
  env | grep PATH
  cat /etc/lsb-release
  uname -a
  pwd
  tree -a -L 1
  echo "*** python -V"
  python -V
  echo "*** pip -V"
  pip -V
  echo "*** terraform -version"
  terraform -version
  echo "*** terragrunt -version"
  terragrunt -version
  echo "*** pre-commit --version"
  pre-commit --version
  terraform-docs markdown document --hide requirements --escape=false --sort-by required . > docs/README.md
  terraform init -upgrade
  terraform plan
  DIR=~/.git-template
  git config --global init.templateDir ${DIR}
  pre-commit init-templatedir -t pre-commit ${DIR}
  pre-commit validate-config
  pre-commit run -a
'
