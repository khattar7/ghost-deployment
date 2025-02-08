#!/bin/bash
set -e

# Find the latest GCP credentials dynamically
export GOOGLE_APPLICATION_CREDENTIALS=$(find /tmp -name "application_default_credentials.json" | head -n 1)

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "Error: GCP credentials file not found!"
    exit 1
fi

echo "Using credentials: $GOOGLE_APPLICATION_CREDENTIALS"

# Collect user inputs
read -p "Enter your GCP Project ID: " project_id
read -p "Enter your SSH username: " ssh_user
read -p "Enter path to SSH public key: " ssh_public_key
read -p "Enter IP to whitelist for SSH: " whitelist_ip
read -sp "Enter Cloud SQL database password: " db_password
echo

# Set Terraform variables
export TF_VAR_project_id="$project_id"
export TF_VAR_ssh_user="$ssh_user"
export TF_VAR_ssh_public_key="$(cat ${ssh_public_key})"
export TF_VAR_whitelist_ip="$whitelist_ip"
export TF_VAR_db_password="$db_password"

# Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# Get outputs
vm_ip=$(terraform output -raw instance_external_ip)
cloudsql_ip=$(terraform output -raw cloudsql_ip)

# Deploy Ghost using Ansible
cd ../ansible
ansible-playbook -i "${vm_ip}," deploy-ghost.yml \
  --extra-vars "db_host=${cloudsql_ip} db_password=${db_password}" \
  --user "${ssh_user}" \
  --private-key "${ssh_public_key%.pub}"

# Cleanup
unset TF_VAR_db_password
