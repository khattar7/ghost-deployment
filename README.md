# ghost-deployment
│
├── deploy.sh                # Shell script to run the deployment
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   └── variables.tf         # Variables for Terraform
│   
├── ansible/
│   ├── deploy-ghost.yml     # Main Terraform configuration
│   └── inventory.ini        # Variables for Terraform
│   
└── README.md               # Instructions for the user


. Prerequisites
•	Google Cloud SDK installed (gcloud CLI)
•	Terraform installed
•	Ansible installed (Some fixes if we face error in installing Ansible sudo apt update --fix-missing 
then: sudo apt install ansible -y)
•	A GCP account with billing enabled


## To download the deployable code from Git:
git clone https://github.com/khattar7/ghost-deployment.git

#Deploy Resources:
cd ghost-deployment
chmod +x deploy.sh
./deploy.sh

# Configure Terraform Variables
project_id      = "your-gcp-project-id"
region          = "us-central1"
whitelist_ip    = "your-ip-address"  # List of IPs that should have access
db_password     = "your-database-password"
ssh_user        = "your-ssh-user" Default: ubuntu
ssh_public_key  = "path-to-your-public-ssh-key" Default: ~/.ssh/my_ssh_key.pub


Finally to Access Ghost:
After deployment, access Ghost at:echo "http://$(terraform output -raw instance_external_ip):2368"



