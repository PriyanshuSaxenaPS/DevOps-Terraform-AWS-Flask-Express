#!/usr/bin/env bash
set -euo pipefail
# Run from repository root after Part 3 Terraform apply created ECR repositories.
REGION="${AWS_REGION:-ap-south-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
FLASK_REPO="$(terraform -chdir=part3-ecs-ecr-alb output -raw flask_ecr_repository_url)"
EXPRESS_REPO="$(terraform -chdir=part3-ecs-ecr-alb output -raw express_ecr_repository_url)"
TAG="${IMAGE_TAG:-v1}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
docker build -t "$FLASK_REPO:$TAG" apps/flask
docker push "$FLASK_REPO:$TAG"
docker build -t "$EXPRESS_REPO:$TAG" apps/express
docker push "$EXPRESS_REPO:$TAG"
