#!/bin/bash

# docker build -t tools .
# docker tag tools:latest star3am/repository:tools
# docker login
# docker push star3am/repository:tools

pwd
docker images | grep tools
docker rmi -f tools
docker buildx create --name tools --use --node tools0
docker buildx inspect
# https://vikaspogu.dev/posts/docker-buildx-setup/
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx build --platform=linux/amd64,linux/arm64 -t tools:latest .
docker buildx imagetools inspect star3am/repository:tools
docker build -t tools .
docker images | grep tools
docker compose run --rm tools bash -c '
  cd /app
  pwd
  tree -a -L 1
  python -V
  pip -V
  cookiecutter --version
  aws --version
  az --version
  gcloud --version
  dbt --version
  kubectl version
  terraform -version
  terragrunt -version
  ~/.local/bin/pre-commit --version
  ~/.local/bin/pre-commit validate-config
  ~/.local/bin/pre-commit run --all-files
'
