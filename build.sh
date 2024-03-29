#!/bin/bash

# Build locally - Docker node
docker build . -t mongo-replica-ctrl:latest

# Build remote - Dockerhub registry
# docker login
# docker buildx build --platform "linux/amd64,linux/arm64,linux/arm/v7" -t jackietreehorn/mongo-replica-ctrl:1.03 -t jackietreehorn/mongo-replica-ctrl:latest --push .

# Build remote DEV - Dockerhub registry
# docker login
# docker buildx build --platform "linux/amd64,linux/arm64,linux/arm/v7" -t jackietreehorn/mongo-replica-ctrl:dev --push .