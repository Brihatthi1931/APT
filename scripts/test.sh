# shellcheck disable=SC2148
ALB=$(terraform -chdir=terraform output -raw alb_dns)
curl http://$ALB/
curl http://$ALB/health
