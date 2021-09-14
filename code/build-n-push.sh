#!/bin/bash

sed -i "s#{{ INTERNAL_BE_LB }}#${INTERNAL_BE_LB}#g" ../../../code/frontend/nginx.conf
docker build -f ../../../code/backend/Dockerfile -t aws-playground-be:${TAG} ../../../code/backend
docker build -f ../../../code/frontend/Dockerfile -t aws-playground-fe:${TAG} ../../../code/frontend
sed -i "s#${INTERNAL_BE_LB}#{{ INTERNAL_BE_LB }}#g" ../../../code/frontend/nginx.conf

aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ${ECR_REPO}

docker tag aws-playground-be:${TAG} ${ECR_BACKEND_REPO}:${TAG}
docker tag aws-playground-fe:${TAG} ${ECR_FRONTEND_REPO}:${TAG}

docker push ${ECR_BACKEND_REPO}:${TAG}
docker push ${ECR_FRONTEND_REPO}:${TAG}
