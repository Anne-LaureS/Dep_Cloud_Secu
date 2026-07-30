# 🟠 AWS — Déploiement Web Sécurisé avec Terraform

Déploiement complet d'une infrastructure web sur AWS (VPC, EC2, Security Group) via Terraform, avec état distant chiffré, accès SSH restreint et détection de dérive de configuration. Région : eu-west-3 (Paris).

![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Security](https://img.shields.io/badge/Security-IMDSv2-2E7D32?style=flat-square&logo=shieldcheck&logoColor=white)
![Encrypted State](https://img.shields.io/badge/State-Encrypted%20S3-1565C0?style=flat-square&logo=amazons3&logoColor=white)
![Drift Detection](https://img.shields.io/badge/Drift-Detection-C62828?style=flat-square&logo=terraform&logoColor=white)
![Nginx](https://img.shields.io/badge/Web%20Server-nginx-009639?style=flat-square&logo=nginx&logoColor=white)
[![Terraform CI](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/terraform-pipeline.yml)

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
- **Accès SSH restreint (ingress)** : ouvert uniquement à l'adresse IP publique de l'opérateur (`/32`), jamais à `0.0.0.0/0`.
- **Sortie HTTPS ouverte (egress)** : le trafic sortant est restreint au port 443 (pas tous les ports/protocoles), mais reste ouvert vers `0.0.0.0/0` — nécessaire pour les mises à jour système et dépôts de paquets. Risque documenté et accepté explicitement dans `envs/dev-aws/.trivyignore` (règle `AWS-0104`).
- **Secrets non versionnés** : `.gitignore` exclut `.terraform/`, `*.tfstate*`, `*.tfplan`, `*.tfvars`.

## 🧪 Détection de dérive

Une modification manuelle du Security Group dans la console AWS (ouverture du port 22 à `0.0.0.0/0`) a été effectuée volontairement pour tester la détection de dérive. `terraform plan` a correctement identifié l'écart entre l'état réel et le code, et `terraform apply` a permis de restaurer la configuration sécurisée.

## ⚙️🔁 Intégration continue (CI/CD)

Ce dépôt utilise GitHub Actions (`.github/workflows/terraform-pipeline.yml`) pour valider et déployer l'infrastructure.

### 🛠️ Ce que fait le pipeline

À chaque `push` sur `main`/`develop` (ou via une Pull Request) :

1. **Format & Lint** — `terraform fmt -check` et `tflint`
2. **Security** — `gitleaks` (détection de secrets) et `trivy` (misconfigurations AWS)
3. **Terraform Plan** — génère un plan d'exécution, archivé en artefact téléchargeable (aucune modification réelle à ce stade)

### 🚦 Déployer réellement (Terraform Apply)

L'`apply` **ne se lance jamais automatiquement**. Pour déployer :

1. Onglet **Actions** → **Terraform CI** → **Run workflow**
2. Attendez que `Terraform Plan` réussisse
3. Une approbation manuelle est requise avant l'`apply` — validez-la depuis l'écran d'approbation qui apparaît sur le run

### 🔑 Secrets requis (Settings → Secrets and variables → Actions)

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM |
| `AWS_SECRET_ACCESS_KEY` | Clé secrète IAM associée |
| `MY_IP` | IP publique autorisée en SSH (`var.my_ip`) |

### ⚠️ Risques de sécurité acceptés

Certaines alertes Trivy sont documentées et ignorées volontairement dans `envs/dev-aws/.trivyignore` (avec justification en commentaire) plutôt que masquées silencieusement — voir ce fichier pour le détail.

## ✍️ Auteur

Anne-Laure S. — Mastère Cybersécurité & Cloud Computing
