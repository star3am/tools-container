#!/bin/bash

# docker build -t tools .
# docker tag tools:latest star3am/repository:tools
# docker login
# docker push star3am/repository:tools

arch=$(uname -m)
if [[ $arch == x86_64* ]]; then
  ARCH="amd64"
elif  [[ $arch == arm64 ]]; then
  ARCH="arm64"
fi
echo "CPU is ${ARCH}"
pwd
docker images | grep tools
docker rmi -f tools-${ARCH}
docker buildx ls
docker buildx rm
docker buildx ls
docker buildx create --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm64/v8 --name tools --use --node tools0
docker buildx use tools
docker buildx inspect
# https://vikaspogu.dev/posts/docker-buildx-setup/
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx build --platform linux/${ARCH} -t tools-${ARCH} --progress=plain --load .
#docker buildx build --platform=linux/amd64,linux/arm64,linux/arm/v7,linux/arm64/v8 --progress=plain -t tools:latest .
docker images | grep tools
docker buildx ls
#docker buildx imagetools inspect star3am/repository:tools
ARCH=${ARCH} docker compose run --rm tools bash -c '
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
  echo "*** az --version"
  az --version
  echo "*** cookiecutter --version"
  cookiecutter --version
  echo "*** aws --version"
  aws --version
  echo "*** gcloud --version"
  gcloud --version
  echo "*** dbt --version"
  dbt --version
  echo "*** kubectl version"
  kubectl version
  echo "*** helm version"
  helm version
  echo "*** terraform -version"
  terraform -version
  echo "*** terragrunt -version"
  terragrunt -version
  echo "*** pre-commit --version"
  pre-commit --version
  echo "*** packer version"
  packer version
  # pre-commit validate-config
  # pre-commit run --all-files
  # echo "*** pip list"
  # pip list
'
