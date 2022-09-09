# Tools Container

A Multi-Arch/Multi-OS Container I use with popular tools, a list will be provided below.

## Install

### Local Development
You will need the following tools to get started before you can use this repo and commence local development

- Docker Desktop
  https://www.docker.com/products/docker-desktop/
- IDE Visual Studio Code (with Remote development in Containers extension)
  https://code.visualstudio.com/docs/remote/containers-tutorial
- Git
  https://git-scm.com/
- Pre-Commit
  https://pre-commit.com/#install

### Build Agent
You will need the following tools installed on the build agent to use this

- Git
- Docker Daemon

## Chipsets Supported
| Name | Amd64 | Arm64
|------|-------|------|
| Tools | ✓ | ✓ |

## Command Line CLI Supported
| Name | Azure | Google | AWS | Kubectl | Dbt | Terraform | Terragrunt | TFENV | Python | Pip | Packer | Cookiecutter | Pre-Commit |
|------|-------|--------|-----|-------|-------|-----------|------------|-------|--------|-----|--------|--------------|------------|
| Tools | ✓   | ✓ | | ✓   | ✓     | ✓     |         ✓            ✓ |    ✓ |     ✓ |  ✓ |     ✓      |
✓ |         ✓ ✓ |

## Clouds Supported
| Name | Azure | Google | AWS |
|------|-------|--------|-----|
| Tools | ✓ | ✓ | ✓ |

## Usage

```shell
./run.sh
```

## Links
- https://nielscautaerts.xyz/making-dockerfiles-architecture-independent.html
-
