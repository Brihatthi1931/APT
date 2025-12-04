#!/bin/bash
echo "Destroying Infrastructure to avoid charges..."
# shellcheck disable=SC2164
cd terraform
terraform destroy -auto-approve
echo "Teardown Complete."