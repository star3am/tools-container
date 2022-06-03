ARG DOTNET_VERSION="3.1.413"
ARG UBUNTU_RELEASE="focal"
FROM mcr.microsoft.com/dotnet/core/sdk:${DOTNET_VERSION}-${UBUNTU_RELEASE}

# Ubuntu
ARG DEBIAN_FRONTEND=noninteractive
ARG MIRROR="http://azure.archive.ubuntu.com"
# UBUNTU_RELEASE must be redeclared because it is used before "FROM"
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG UBUNTU_RELEASE="focal"
ARG UBUNTU_VERSION="20.04"
ARG PKGS="apt-transport-https ca-certificates gnupg jq software-properties-common unzip zip python3.9 python3-pip python3-dev python3-virtualenv apt-utils build-essential tree"

# Env vars
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    echo "TARGETPLATFORM: ${TARGETPLATFORM}" && \
    echo "ARCHITECTURE: ${ARCHITECTURE}"

# Apt Updates
RUN sed -ri \
    -e "s^http://.*archive\.ubuntu\.com^${MIRROR}^" \
    -e "1i deb ${MIRROR}/ubuntu/ ${UBUNTU_RELEASE}-security main restricted universe multiverse\n" \
    /etc/apt/sources.list && \
    apt update && \
    apt install --no-install-recommends -y ${PKGS} && \
    apt upgrade -y && \
    apt autoremove --purge -y && \
    find /opt /usr/lib -name __pycache__ -print0 | xargs --null rm -rf && \
    rm -rf /var/lib/apt/lists/*

# python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 --force && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 --force

# packages.microsoft.com repo key
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

# Azure CLI
# PEM file removal is to stop Aquasec from complaining about sensitive data in the resulting image
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    add-apt-repository "deb [arch=${ARCHITECTURE}] https://packages.microsoft.com/repos/azure-cli/ ${UBUNTU_RELEASE} main" && \
    apt install --no-install-recommends -y azure-cli && \
    find /opt /usr/lib -name __pycache__ -print0 | xargs --null rm -rf && \
    find /opt/az/lib/python3.6/test/ -iname '*.pem' -ls -delete || true && \
    rm -rf /var/lib/apt/lists/*

# Microsoft ODBC Driver for SQL Server on Linux
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#ubuntu17
# https://docs.microsoft.com/en-us/windows-server/administration/linux-package-repository-for-microsoft-software
# The chown is because libodbc1 and odbcinst1debian2 leave files with no owner hanging around,
# and our CIS benchmark check complains about them.
ARG ACCEPT_EULA=Y
RUN apt-add-repository https://packages.microsoft.com/ubuntu/${UBUNTU_VERSION}/prod && \
    apt install --no-install-recommends -y msodbcsql17 mssql-tools && \
    find /var/lib/dpkg/info \( -nouser -o -nogroup \) -print0 | xargs --no-run-if-empty --null chown root:root && \
    find /opt /usr/lib -name __pycache__ -print0 | xargs --null rm -rf && \
    rm -rf /var/lib/apt/lists/*

# Microsoft hosted agent uses a User `vsts` with UID `1001` and GID `117`
# https://github.com/microsoft/azure-pipelines-agent/issues/2043#issuecomment-524683461
ARG USER_ID="1001"
RUN adduser --disabled-password --gecos "" --shell /bin/bash --uid ${USER_ID} ubuntu

# ARG TERRAFORM_VERSION="latest"
# RUN echo ${TERRAFORM_VERSION} > /opt/.terraform-version 2>&1
COPY --chown=ubuntu ./.terraform-version /opt/.terraform-version

# ARG TERRAGRUNT_VERSION="latest"
# RUN echo ${TERRAGRUNT_VERSION} > /opt/.terragrunt-version 2>&1
COPY --chown=ubuntu ./.terragrunt-version /opt/.terragrunt-version

# tfenv
RUN git clone --depth 1 https://github.com/tfutils/tfenv.git /opt/tfenv && \
    ln -s /opt/tfenv/bin/tfenv /usr/local/bin && \
    ln -s /opt/tfenv/bin/terraform /usr/local/bin && \
    mkdir -p /opt/tfenv/versions && \
    cd /opt && \
    tfenv install && \
    chown -R ubuntu:root /opt/tfenv

# tgenv
RUN git clone --depth 1 https://github.com/cunymatthieu/tgenv.git /opt/tgenv && \
    ln -s /opt/tgenv/bin/tgenv /usr/local/bin && \
    ln -s /opt/tgenv/bin/terragrunt /usr/local/bin && \
    mkdir -p /opt/tgenv/versions && \
    cd /opt && \
    tgenv install && \
    chown -R ubuntu:root /opt/tgenv

# tfsec
ARG TFSEC_VERSION="0.58.14"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    curl -Lo /usr/local/bin/tfsec https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCHITECTURE} && \
    chmod +x /usr/local/bin/tfsec

# tflint
ARG TFLINT_VERSION="0.30.0"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    curl -Lo /tmp/tflint.zip https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCHITECTURE}.zip && \
    unzip /tmp/tflint.zip -d /usr/local/bin && \
    python3 -m pip install --quiet yamllint

# tflint azurerm plugin
ARG TFLINT_AZURERM_PLUGIN="0.12.0"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    mkdir -p /home/ubuntu/.tflint.d/plugins && \
    chown -R ubuntu:ubuntu /home/ubuntu/.tflint.d && \
    curl -Lo /tmp/tflint-ruleset-azurerm_linux_${ARCHITECTURE}.zip https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/v${TFLINT_AZURERM_PLUGIN}/tflint-ruleset-azurerm_linux_${ARCHITECTURE}.zip && \                                                         
    unzip /tmp/tflint-ruleset-azurerm_linux_${ARCHITECTURE}.zip -d /home/ubuntu/.tflint.d/plugins

# terraform-docs
ARG TERRAFORM_DOCS_VERSION="0.16.0"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    curl -Lo /tmp/terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${ARCHITECTURE}.tar.gz && \
    cd /tmp && \
    tar -xzf terraform-docs.tar.gz && \
    chmod +x terraform-docs && \
    mv terraform-docs /usr/local/bin/terraform-docs

# kubectl
ARG KUBECTL_VERSION="1.18.10"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl && \
    chmod +x /usr/local/bin/kubectl

# terraform plugin-cache
RUN mkdir -p /home/ubuntu/.terraform.d/plugin-cache && \
    chown -R ubuntu:ubuntu /home/ubuntu/.terraform.d

# cookie-cutter https://github.com/cookiecutter/cookiecutter/blob/master/docs/installation.rst
RUN python3 -m pip install --quiet --upgrade cookiecutter

# dbt https://github.com/dbt-labs/dbt-core/blob/main/docker/Dockerfile
ARG dbt_core_ref=dbt-core@v1.2.0a1
ARG dbt_postgres_ref=dbt-core@v1.2.0a1
ARG dbt_redshift_ref=dbt-redshift@v1.0.0
ARG dbt_bigquery_ref=dbt-bigquery@v1.0.0
ARG dbt_snowflake_ref=dbt-snowflake@v1.0.0
ARG dbt_third_party
RUN python3 -m pip install --quiet --no-cache "git+https://github.com/dbt-labs/${dbt_redshift_ref}#egg=dbt-redshift"
RUN python3 -m pip install --quiet --no-cache "git+https://github.com/dbt-labs/${dbt_bigquery_ref}#egg=dbt-bigquery"
RUN python3 -m pip install --quiet --no-cache "git+https://github.com/dbt-labs/${dbt_snowflake_ref}#egg=dbt-snowflake"
RUN python3 -m pip install --quiet --no-cache "git+https://github.com/dbt-labs/${dbt_postgres_ref}#egg=dbt-postgres&subdirectory=plugins/postgres"

# aws cli https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# https://aws.amazon.com/blogs/developer/aws-cli-v2-now-available-for-linux-arm/
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=x86_64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=aarch64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=aarch64; else ARCHITECTURE=x86_64; fi && \
    curl -Lo "/tmp/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-${ARCHITECTURE}.zip" && \
    cd /tmp && \
    unzip -qq awscliv2.zip && \
    ./aws/install --update

# gcloud cli https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile https://cloud.google.com/sdk/docs/install#deb
ARG CLOUD_SDK_VERSION=386.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH "$PATH:/opt/google-cloud-sdk/bin/"
RUN apt-get -qqy update && apt-get install -qqy \
        curl \
        python3-dev \
        python3-crcmod \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git \
        make \
        gnupg && \
    # TODO: Fixme: The repository 'https://packages.cloud.google.com/apt cloud-sdk-focal Release' does not have a Release file.
    # INFO: https://packages.cloud.google.com/apt/dists Ubuntu Focal Realease does not exist, we use Ubuntu Bionic instead
    # export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    export CLOUD_SDK_REPO="cloud-sdk-bionic" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python-extras=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-java=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-go=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datalab=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datastore-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-pubsub-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-bigtable-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-firestore-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-spanner-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-cbt=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-kpt=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-local-extract=${CLOUD_SDK_VERSION}-0

# packer
ARG PACKER_VERSION="1.7.2"
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
    curl -L https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${ARCHITECTURE}.zip -o packer.zip && \
    unzip packer.zip -d /usr/local/bin && \
    rm packer.zip

# docker https://github.com/docker/docker-install
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    usermod -aG docker ubuntu

# cleanup
RUN apt autoremove --purge -y && \
    find /opt /usr/lib -name __pycache__ -print0 | xargs --null rm -rf && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=ubuntu ./ /app
#RUN rm -rf /app/*

USER ubuntu
WORKDIR /app
