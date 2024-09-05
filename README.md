# Deploy two AWS Ubuntu servers running Jenkins, Prometheus and Grafana containers in a hierarchical federation model and scrape some basic metrics from each into the primary instance.

# Install Terraform
https://developer.hashicorp.com/terraform/install
# Install Ansible
https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-distros
# Install AWS CLI
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# Generate a key pair
$ ssh-keygen -t ed25519 -N "" -m pem -f ~/keys/aws-kp-ecdsa