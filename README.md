# 🟠 AWS — Déploiement Web Sécurisé avec Terraform, Make & Ansible

Déploiement et configuration complets d'une infrastructure web sur AWS (VPC, EC2, Security Group), provisionnée par Terraform et configurée par Ansible, avec deux pipelines CI/CD au choix (approbation manuelle ou automatisation complète via `make`). État distant chiffré, accès SSH restreint et détection de dérive de configuration. Région : eu-west-3 (Paris).

![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?style=flat-square&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Security](https://img.shields.io/badge/Security-IMDSv2-2E7D32?style=flat-square)
![Encrypted State](https://img.shields.io/badge/State-Encrypted%20S3-1565C0?style=flat-square&logo=amazons3&logoColor=white)
![Drift Detection](https://img.shields.io/badge/Drift-Detection-C62828?style=flat-square&logo=terraform&logoColor=white)
![Nginx](https://img.shields.io/badge/Web%20Server-nginx-009639?style=flat-square&logo=nginx&logoColor=white)
![Ansible](https://img.shields.io/badge/Config-Ansible-000000?style=flat-square&logo=ansible&logoColor=white)
![Secrets Scan](https://img.shields.io/badge/Secrets-gitleaks-2E7D32?style=flat-square)
![Misconfig Scan](https://img.shields.io/badge/Misconfig-Trivy-2E7D32?style=flat-square)

[![Terraform CI](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/terraform-pipeline.yml)
[![Make Pipeline](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/make-pipeline.yml/badge.svg)](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/make-pipeline.yml)
[![Destroy](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/destroy-pipeline.yml/badge.svg)](https://github.com/Anne-LaureS/Dep_Cloud_Secu/actions/workflows/destroy-pipeline.yml)

## 📁 Structure du dépôt

```
Dep_Cloud_Secu/
├── .github/
│   └── workflows/
│       ├── terraform-pipeline.yml   # Validations → Plan → Apply (approbation manuelle)
│       ├── make-pipeline.yml        # Pipeline entièrement automatisé via make
│       └── destroy-pipeline.yml     # Destruction protégée par confirmation
├── envs/
│   └── dev-aws/
│       ├── backend.tf
│       ├── variables.tf
│       ├── network.tf
│       ├── security.tf
│       ├── compute.tf
│       ├── outputs.tf
│       ├── ansible-key.pub          # Clé publique injectée dans l'instance
│       ├── .trivyignore             # Risques évalués et acceptés (documentés)
│       └── .terraform.lock.hcl
├── ansible/
│   ├── playbook.yml                 # Configure nginx, la page web, Netdata
│   └── index.html                   # Page servie par nginx
├── docs/
│   ├── tp2-rapport.md
│   ├── tp2-rapport.tex
│   └── img/                         # Captures d'écran du rapport
├── Makefile                         # Cibles fmt/tflint/trivy/init/apply/inventory/deploy/destroy
├── .gitignore
└── README.md
```

## ⚙️ Prérequis

- Terraform >= 1.10 (pour `use_lockfile`)
- AWS CLI configuré (`aws configure`)
- Un bucket S3 existant pour le state (créé manuellement, versioning + chiffrement + Block Public Access activés)

## 🚀 Démarrage

### Option recommandée — via GitHub Actions

1. Configurez les 4 secrets requis (`Settings → Secrets and variables → Actions`) : `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `MY_IP`, `ANSIBLE_SSH_PRIVATE_KEY`
2. Onglet **Actions** → choisissez un workflow :
   - **`make-pipeline.yml`** — déploiement complet automatisé (validations → EC2 → Ansible), en un clic
   - **`terraform-pipeline.yml`** — même chose, avec approbation manuelle avant l'`apply`
3. **Run workflow**

### Option locale (développement / débogage)

```bash
git clone <url-du-depot>
cd Dep_Cloud_Secu

# Générer une paire de clés SSH pour l'instance (si pas déjà fait)
ssh-keygen -t ed25519 -f ~/.ssh/ansible-key -N ""
cp ~/.ssh/ansible-key.pub envs/dev-aws/ansible-key.pub

# Créer un terraform.tfvars local (non versionné) avec votre IP publique :
# echo 'my_ip = "VOTRE_IP_PUBLIQUE"' > envs/dev-aws/terraform.tfvars

export TF_VAR_my_ip="VOTRE_IP_PUBLIQUE"
make init
make apply
make inventory
make deploy
```

### Détruire l'infrastructure

Via GitHub Actions (`destroy-pipeline.yml`, confirmation `DESTROY` requise), ou en local :
```bash
make destroy
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

Ce dépôt propose **trois workflows GitHub Actions** distincts, selon le besoin :

| Workflow | Déclenchement | Comportement |
|---|---|---|
| `terraform-pipeline.yml` | `push` / `workflow_dispatch` | Validations → Plan → **Apply avec approbation manuelle** |
| `make-pipeline.yml` | `workflow_dispatch` | Pipeline entièrement automatisé (via `make`) : validations → provisionnement conditionnel → inventaire → déploiement Ansible, **sans intervention manuelle** |
| `destroy-pipeline.yml` | `workflow_dispatch` | Détruit l'infrastructure — protégé par une confirmation textuelle obligatoire (`DESTROY`) |

Les trois pipelines partagent le même état Terraform (backend S3) : peu importe lequel a créé l'infrastructure, `destroy-pipeline.yml` la détruit proprement.

### 🔑 Secrets requis (Settings → Secrets and variables → Actions)

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM |
| `AWS_SECRET_ACCESS_KEY` | Clé secrète IAM associée |
| `MY_IP` | IP publique autorisée en SSH (`var.my_ip`) |
| `ANSIBLE_SSH_PRIVATE_KEY` | Clé privée SSH pour le déploiement Ansible |

### ⚠️ Risques de sécurité acceptés

Documentés et justifiés dans `envs/dev-aws/.trivyignore` : sortie réseau nécessaire (HTTP/HTTPS), IP publique de l'instance (architecture web publique voulue), et accès SSH temporairement élargi pour permettre au runner CI de déployer via Ansible.

## ✍️ Auteur

Anne-Laure S. — Mastère Cybersécurité & Cloud Computing
