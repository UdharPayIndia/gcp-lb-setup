#!/bin/bash
set -e

# ==============================================================================
# AWS EC2 Launch Script for Nginx Proxy (AWS to GCP)
# ==============================================================================

echo "Launching AWS EC2 instance: staging-aws-to-gcp-nginx-proxy..."

# 1. Create the VM instance and attach the startup script as user-data
aws ec2 run-instances \
    --image-id 'ami-0a15c80c30715cc92' \
    --instance-type 't2.medium' \
    --key-name 'aishwary' \
    --block-device-mappings '{"DeviceName":"/dev/xvda","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-001c2edebb4685aeb","VolumeSize":20,"VolumeType":"gp3","Throughput":125}}' \
    --network-interfaces '{"SubnetId":"subnet-08b4a704e9f3e10de","AssociatePublicIpAddress":false,"DeviceIndex":0,"Ipv6AddressCount":0,"Groups":["sg-03f9dd394a10dbce2","sg-080ef88b5b79ae0f9","sg-0d21ca73df63209b7"]}' \
    --credit-specification '{"CpuCredits":"standard"}' \
    --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"staging-aws-to-gcp-nginx-proxy"}]}' \
    --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
    --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' \
    --count '1' \
    --user-data file://startup.sh

echo "=============================================================================="
echo "Deployment command executed successfully!"
echo "The EC2 instance is launching and running the startup.sh script."
echo "=============================================================================="
