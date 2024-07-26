# Set up two Ubuntu cloud servers that run Jenkins, Prometheus and Grafana in a hierarchical federation model and scrape some basic metrics from each into the primary instance.

# Install Ansible, Terraform and AWS CLI on the control node
https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-distros
https://developer.hashicorp.com/terraform/install
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# Generate a key pair
$ ssh-keygen -t ed25519 -N "" -m pem -f ~/keys/aws-kp-ecdsa

# Configure AWS CLI
$ aws configure