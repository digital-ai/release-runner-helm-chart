#!/bin/bash

PLATFORM_URL="https://api.staging.digital.ai"
DEFAULT_WORKSPACE_ROOT="../.."

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
      shift # past argument
      shift # past value
      ;;
    --workspace)
      WORKSPACE_ROOT="$2"
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
  echo "Use --version to define the version of the image of Digital.ai Release Runner to use in the agent runtime"
  MISSING_REQUIRED=true
fi

if [ ${MISSING_REQUIRED} ]; then
  exit 1
fi

if [ -z ${WORKSPACE_ROOT} ]; then
  WORKSPACE_ROOT=${DEFAULT_WORKSPACE_ROOT}
fi

# Search for agent by name
RESPONSE=$(${WORKSPACE_ROOT}/scripts/dai-platform/find_agent_runtime_by_name.sh --version ${IMAGE_VERSION} --token ${BEARER_TOKEN})

COUNT=$(jq -r '.pagination.total_available' <<< ${RESPONSE})

if [ ${COUNT} -eq 0 ]; then
  echo "There are no agents found for version ${IMAGE_VERSION}"
  exit 1
fi

for id in $(jq -r '.agent_runtimes[].id' <<< ${RESPONSE}); do
  echo "Deleting agent with id ${id}"
  curl --silent --request DELETE "${PLATFORM_URL}/workload/v1/agent_runtimes/${id}" \
    --header "Authorization: Bearer ${BEARER_TOKEN}"
done
