# 🟠 AWS — Déploiement Web Sécurisé avec Terraform

Déploiement complet d'une infrastructure web sur AWS (VPC, EC2, Security Group) via Terraform, avec état distant chiffré, accès SSH restreint et détection de dérive de configuration. Région : eu-west-3 (Paris).

![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Security](https://img.shields.io/badge/Security-IMDSv2-2E7D32?style=flat-square&logo=shieldcheck&logoColor=white)
![Encrypted State](https://img.shields.io/badge/State-Encrypted%20S3-1565C0?style=flat-square&logo=amazons3&logoColor=white)
![Drift Detection](https://img.shields.io/badge/Drift-Detection-C62828?style=flat-square&logo=terraform&logoColor=white)
![Nginx](https://img.shields.io/badge/Web%20Server-nginx-009639?style=flat-square&logo=nginx&logoColor=white)

## 📁 Structure du dépôt

```
Dep_Cloud_Secu/
├── envs/
│   └── dev-aws/
│       ├── backend.tf        # Backend S3 chiffré + verrouillage natif
│       ├── variables.tf      # Variables (IP autorisée, type d'instance)
│       ├── network.tf        # VPC, IGW, subnet public, route table
│       ├── security.tf       # Security Group (HTTP public, SSH restreint)
│       ├── compute.tf        # Instance EC2 (nginx, IMDSv2, disque chiffré)
│       ├── outputs.tf        # IP publique de l'instance
│       └── .terraform.lock.hcl
├── .gitignore
└── README.md
```

## ⚙️ Prérequis

- Terraform >= 1.10 (pour `use_lockfile`)
- AWS CLI configuré (`aws configure`)
- Un bucket S3 existant pour le state (créé manuellement, versioning + chiffrement + Block Public Access activés)

## 🚀 Démarrage

```bash
git clone <url-du-depot>
cd Dep_Cloud_Secu/envs/dev-aws

# Créer un terraform.tfvars local (non versionné) avec votre IP publique :
# my_ip = "VOTRE_IP_PUBLIQUE"

terraform init
terraform plan -out=dev.tfplan
terraform apply "dev.tfplan"
```

## 🔒 Sécurité

- **État distant chiffré** : backend S3 avec `encrypt = true`, `use_lockfile = true`, bucket en Block Public Access + SSE-S3 + versioning.
- **IMDSv2 obligatoire** : `metadata_options.http_tokens = "required"` sur l'instance EC2.
- **Disque racine chiffré** : `root_block_device.encrypted = true`.
- **Accès SSH restreint** : ouvert uniquement à l'adresse IP publique de l'opérateur (`/32`), jamais à `0.0.0.0/0`.
- **Secrets non versionnés** : `.gitignore` exclut `.terraform/`, `*.tfstate*`, `*.tfplan`, `*.tfvars`.

## 🧪 Détection de dérive

Une modification manuelle du Security Group dans la console AWS (ouverture du port 22 à `0.0.0.0/0`) a été effectuée volontairement pour tester la détection de dérive. `terraform plan` a correctement identifié l'écart entre l'état réel et le code, et `terraform apply` a permis de restaurer la configuration sécurisée.

## ✍️ Auteur

Anne-Laure S. — Mastère Cybersécurité & Cloud Computing
