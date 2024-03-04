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

HELM_DIR="${WORKSPACE_ROOT}"
GENERATED_YAML_FILE="${WORKSPACE_ROOT}/cloud-connector-k8s.yaml"

# Generate the yaml file for cloud-connector
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm template runner ${HELM_DIR} -f ${HELM_DIR}/values-cloud-connector.yaml > ${GENERATED_YAML_FILE}

if [ -z ${GENERATED_YAML_FILE} ]; then
  echo "Failed to generate yaml file for k8s template in agent"
  exit 1
fi

# Determine the variables that need to be defined in the agent runtime definition
AGENT_VARIABLES=$(${WORKSPACE_ROOT}/scripts/dai-platform/get_cloud_connector_variables.sh --workspace "${WORKSPACE_ROOT}")

# Build the JSON for the POST body to create the agent runtime image
CREATE_AGENT_BODY=$(jq \
  --arg name "runner-${IMAGE_VERSION}" \
  --arg version "${IMAGE_VERSION}" \
  --argjson variables "${AGENT_VARIABLES}" \
  '.name = $name | .images[0].latest_tag = $version | .variables = $variables' \
  ${WORKSPACE_ROOT}/scripts/dai-platform/json/create_agent_runtime.json)

# Create a new agent runtime image
AGENT_RUNTIME_ID=$(curl --silent --request POST "${PLATFORM_URL}/workload/v1/agent_runtimes/" \
  --header "Authorization: Bearer ${BEARER_TOKEN}" \
  --header 'Content-Type: application/json' \
  --data-raw "${CREATE_AGENT_BODY}" \
  | jq -r .agent_runtime.id)

echo "Created agent runtime definition: ${AGENT_RUNTIME_ID}"

curl --silent --request PATCH "${PLATFORM_URL}/workload/v1/agent_runtimes/${AGENT_RUNTIME_ID}/template" \
  --header "Authorization: Bearer ${BEARER_TOKEN}" \
  --form "k8s_template=@${GENERATED_YAML_FILE}"

echo "Uploaded k8s template to agent runtime definition: ${AGENT_RUNTIME_ID}"
