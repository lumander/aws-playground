#!/bin/bash
#dependencies git docker aws and terraform

ENVIRONMENT=$1 #dev
DEPLOY=$2 #init|infrastructure|code|teardown
STATE_BUCKET=$3

declare -a infrastructure_order=("networking" "ecs" "rds" "webapp")
declare -a teardown_order=("webapp" "rds" "ecs" "networking")

TAG=$(git rev-parse --short=8 HEAD)
## infrastructure deploy
if [ $DEPLOY == 'init' ]
  then
    terraform -chdir=infrastructure/global/s3 init
    terraform -chdir=infrastructure/global/s3 apply -var="environment=${ENVIRONMENT}" -auto-approve
elif [ $DEPLOY == 'infrastructure' ]
  then
    for infra in "${infrastructure_order[@]}"; do
      terraform -chdir=infrastructure/$ENVIRONMENT/${infra} init -backend-config=../${ENVIRONMENT}-backend.hcl
      terraform -chdir=infrastructure/$ENVIRONMENT/${infra} apply -var="state_bucket=${STATE_BUCKET}" -var="git_tag=${TAG}" -auto-approve
	  done
elif [ $DEPLOY == 'code' ]
  then
	terraform -chdir=infrastructure/$ENVIRONMENT/webapp init -backend-config=../${ENVIRONMENT}-backend.hcl
  terraform -chdir=infrastructure/${ENVIRONMENT}/webapp apply -var="state_bucket=${STATE_BUCKET}" -var="git_tag=${TAG}" -auto-approve
elif [ $DEPLOY == 'teardown' ]
  then
    for infra in "${teardown_order[@]}"; do
      terraform -chdir=infrastructure/$ENVIRONMENT/${infra} init -backend-config=../${ENVIRONMENT}-backend.hcl
      terraform -chdir=infrastructure/$ENVIRONMENT/${infra} destroy -var="state_bucket=${STATE_BUCKET}" -var="git_tag=${TAG}" -auto-approve
	  done
else
  echo "Unknown operation: aborting"
fi
