# Build a prometheus instance on AWS using Terraform and Ansible to automate deployed ec2 instances

# Install Ansible, Terraform and AWS CLI on the control node
https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-distros
https://developer.hashicorp.com/terraform/install
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# Generate a key pair
$ ssh-keygen -t ed25519 -N "" -m pem -f ~/keys/prometheus-kp-ecdsa

# Configure AWS CLI
$ aws configure

# Source variables
$ source ansible/vars.sh

# Deploy ec2 instances from terraform directory
$ terraform apply -auto-approve

# Deploy containers from ansible directory
$ ansible-playbook prometheus.playbook.yaml