#!/bin/bash

repository_url=$1

# Build the Docker image locally
docker build -t quiz-app:latest .

# Authenticate Docker to your ECR registry
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $repository_url

# Tag the Docker image
docker tag quiz-app:latest $repository_url:latest

# Push the Docker image to ECR
docker push $repository_url:latest
