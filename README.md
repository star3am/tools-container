# Tools Container

A MultiArch Container I use with popular tools, a list will be provided below. 

## Chipsets Supported
| Name | Amd64 | Arm64
|------|-------|------|
| Tools | ✓ | ✓ |

## Command Line CLI Supported
| Name | Azure | Google | AWS | Kubectl | Dbt | MS SQL
|------|-------|--------|-----|-------|-------|--------|
| Tools | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Clouds Supported
| Name | Azure | Google | AWS |
|------|-------|--------|-----|
| Tools | ✓ | ✓ | ✓ |

## Usage

```shell
docker compose run --rm tools bash -c '
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
  pwd'
```
