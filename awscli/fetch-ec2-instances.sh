#!/usr/bin/env bash

aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value | [0], PrivateIpAddress, PublicIpAddress]" --output table