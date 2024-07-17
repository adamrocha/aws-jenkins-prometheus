# source this file before using ansible
# source vars.sh

#Set Private KEY for SSH
export ANSIBLE_PRIVATE_KEY_FILE=${HOME}/keys/prometheus-kp-ecdsa

#Set Ansible Inventory configuration
export ANSIBLE_INVENTORY=$(pwd)/inventory.aws_ec2.yml

echo ANSIBLE_PRIVATE_KEY_FILE=$ANSIBLE_PRIVATE_KEY_FILE
echo ANSIBLE_INVENTORY=$ANSIBLE_INVENTORY
