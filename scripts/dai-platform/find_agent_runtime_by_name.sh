#!/bin/bash

PLATFORM_URL="https://api.staging.digital.ai"

while [[ $# -gt 0 ]]; do
  ARG_COUNT=$#
  case $1 in
    --token)
      BEARER_TOKEN="$2"
      shift # past argument
      shift # past value
      ;;
    --version)
      IMAGE_VERSION="$2"
      IMAGE_NAME="runner-${IMAGE_VERSION}"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
  if [ ${ARG_COUNT} -eq $# ]; then
    echo "Arguments have not been processed correctly, there should be fewer arguments remaining after processing one"
    exit 1
  fi
done

if [ -z ${BEARER_TOKEN} ]; then
  echo "Use --token to define the bearer token to use in API requests"
  MISSING_REQUIRED=true
fi
if [ -z ${IMAGE_VERSION} ]; then
  echo "Use --version to define the version of the image of Digital.ai Release Runner search for"
  MISSING_REQUIRED=true
fi

if [ ${MISSING_REQUIRED} ]; then
  exit 1
fi

# Search for agent by name
curl --silent --request GET "${PLATFORM_URL}/workload/v1/agent_runtimes?filter=name:${IMAGE_NAME}" \
  --header "Authorization: Bearer ${BEARER_TOKEN}" \
  | jq
