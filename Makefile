SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

TF_DIR      := envs/dev-aws
ANSIBLE_DIR := ansible

.DEFAULT_GOAL := help

.PHONY: help fmt tflint trivy init apply inventory deploy destroy

help: ## Affiche cette aide (liste des cibles disponibles)
	@echo "Cibles disponibles :"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

fmt: ## Étape 1 — vérifie le formatage Terraform
	terraform -chdir=$(TF_DIR) fmt -check -recursive

tflint: ## Étape 1 — analyse qualité / erreurs de configuration Terraform
	tflint --chdir=$(TF_DIR) --init
	tflint --chdir=$(TF_DIR) --minimum-failure-severity=error

trivy: ## Étape 1 — recherche vulnérabilités et mauvaises configurations
	trivy config --severity HIGH,CRITICAL --exit-code 1 --skip-version-check \
		--ignorefile $(TF_DIR)/.trivyignore $(TF_DIR)

init: ## Étape 2 — initialise Terraform
	terraform -chdir=$(TF_DIR) init

apply: ## Étape 2 — crée l'instance EC2 (uniquement si l'étape 1 est passée)
	terraform -chdir=$(TF_DIR) apply -input=false -auto-approve

inventory: ## Étape 3 — génère l'inventaire Ansible depuis l'IP de sortie Terraform
	IP=$$(terraform -chdir=$(TF_DIR) output -raw instance_public_ip); \
	echo "[webservers]" > $(ANSIBLE_DIR)/inventory.ini; \
	echo "$$IP ansible_user=ubuntu ansible_ssh_private_key_file=/tmp/ansible_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> $(ANSIBLE_DIR)/inventory.ini; \
	echo "Inventaire généré pour $$IP"

deploy: ## Étape 4 — configure la machine via Ansible
	ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml

destroy: ## Détruit l'infrastructure (irréversible)
	terraform -chdir=$(TF_DIR) destroy -input=false -auto-approve
