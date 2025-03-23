#!/usr/bin/env bash

aws ec2 describe-instances \
    --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}" \
    --output table