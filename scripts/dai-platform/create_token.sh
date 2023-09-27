#!/bin/bash

URL="https://identity.staging.digital.ai"

while [[ $# -gt 0 ]]; do
  ARG_COUNT=$#
  case $1 in
    --user)
      PLATFORM_USER="$2"
      shift # past argument
      shift # past value
      ;;
    --pw)
      PLATFORM_PW="$2"
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

if [ -z ${PLATFORM_USER} ]; then
  echo "Use --user to define the user to create a token for"
  MISSING_REQUIRED=true
fi
if [ -z ${PLATFORM_PW} ]; then
  echo "Use --pw to define the password for the user to create a token for"
  MISSING_REQUIRED=true
fi

if [ ${MISSING_REQUIRED} ]; then
  exit 1
fi

# Create the bearer token to use in API requests
curl --silent --request POST "${URL}/auth/realms/digitalai/protocol/openid-connect/token" \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_secret=${PLATFORM_PW}" \
  --data-urlencode "client_id=${PLATFORM_USER}" \
  --data-urlencode 'scope=openid dai-svc' \
  | jq -r .access_token
