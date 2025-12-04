#!/bin/bash
echo "Starting One-Click Deployment..."
# shellcheck disable=SC2164
cd terraform
terraform init
terraform apply -auto-approve
echo "Deployment Complete."
echo "Access your API at: http://$(terraform output -raw alb_dns_name)"
echo "Test health at: http://$(terraform output -raw alb_dns_name)/health"