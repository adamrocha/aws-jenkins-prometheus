# Build a prometheus instance on AWS using Terraform and Ansible to automate deployed ec2 instances

# Install Ansible on the control node
$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt update
$ sudo apt install ansible

# Generate a key pair
$ ssh-keygen -t ed25519 -N "" -m pem -f ~/keys/prometheus-kp-config-user-ecdsa

# Set permissions
$ chmod 600 $HOME/keys/prometheus_kp_infradmin.pem

# Set AWS keys
$ aws configure

# Source variables
$ source ansible/vars.sh

# Deploy ec2 instances from terraform directory
$ terraform apply -auto-approve

# Deploy containers from ansible directory
$ ansible-playbook prometheus.playbook.yaml