#!/bin/bash

IDENTITY_URL="https://identity.staging.digital.ai"
API_URL="https://api.staging.digital.ai"

####
#### Input variables, you can uncomment and hardcode values to bypass requiring the parameter when calling this script.
#### There may be other input variables that aren't listed here because they don't make sense to have hardcoded
####

#INPUT_USER=""                # username for tenant"
#INPUT_PW=""                  # password for tenant user"
#INPUT_DOMAIN=""              # vanity domain for the tenant
#INPUT_ACCOUNT=""             # account id for the tenant
#INPUT_ALIAS=""               # the alias property in the agent instance, also the name of the namespace used in k3d
####
# For values used in the "variables" property of the agent instance use exact same name as the variable the API needs
####
#RUNNER_REGISTRATION_TOKEN=""                         # api token from release used register remote-runner

# Parse arguments to script
while [[ $# -gt 0 ]]; do
  ARG_COUNT=$#
  case $1 in
    --user) # Username for the tenant, only needed if bearer token is not supplied
      INPUT_USER="$2"
      shift # past argument
      shift # past value
      ;;
    --pw) # Password for the tenant, only needed if bearer token is not supplied
      INPUT_PW="$2"
      shift # past argument
      shift # past value
      ;;
    --token) # Bearer token for the tenant to use in API calls, or supply user and password so a token can be created
      INPUT_TOKEN="$2"
      shift # past argument
      shift # past value
      ;;
    --version) # Runtime search option #1: remote-runner version to search for matching agent runtimes
      INPUT_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    --runtimeName) # Runtime search option #2: Name of agent runtime to use
      INPUT_RUNTIME_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    --runtimeId) # Runtime search option #3: ID of agent runtime
      INPUT_RUNTIME_ID="$2"
      shift # past argument
      shift # past value
      ;;
    --domain) # Vanity domain for the tenant
      INPUT_DOMAIN="$2"
      shift # past argument
      shift # past value
      ;;
    --account) # Account id for the tenant
      INPUT_ACCOUNT="$2"
      shift # past argument
      shift # past value
      ;;
    --agentAlias) # the namespace of the agent instance in k3d
      INPUT_ALIAS="$2"
      shift # past argument
      shift # past value
      ;;
    --releaseToken) # token for registering remote-runner with
      RUNNER_REGISTRATION_TOKEN="$2"
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

#####################################################
# Check input params
#####################################################

# Check auth specific arguments
if [ -z ${INPUT_TOKEN} ]; then
  if [ ! -z ${INPUT_USER} ] && [ ! -z ${INPUT_PW} ]; then
    TENANT_USER="${INPUT_USER}"
    TENANT_PW="${INPUT_PW}"
  else
    echo "Use --token to define the bearer token to use or specify username and password with --user and --pw"
    MISSING_REQUIRED=true
  fi
else
  TENANT_TOKEN="${INPUT_TOKEN}"
fi

# Check agent runtime search specific arguments
if [ -z ${INPUT_RUNTIME_ID} ] && [ -z ${INPUT_RUNTIME_NAME} ] && [ -z ${INPUT_VERSION} ]; then
    echo "Use one of the following options to select a agent runtime to create the agent from:"
    echo "    --runtimeId <id> : to search by id for the agent runtime"
    echo "    --runtimeName <name> : to search for agent runtimes matching the name"
    echo "    --version <version> : to search for agent runtimes using a specific remote-runner image version"
    MISSING_REQUIRED=true
else
  if [ ! -z ${INPUT_RUNTIME_ID} ]; then
    AGENT_RUNTIME_ID=${INPUT_RUNTIME_ID}
  elif [ ! -z ${INPUT_RUNTIME_NAME} ]; then
    SEARCH_NAME=${INPUT_RUNTIME_NAME}
  else
    SEARCH_VERSION=${INPUT_VERSION}
  fi
fi

if [ -z ${INPUT_DOMAIN} ]; then
  echo "Use --domain to define the vanity domain for the tenant"
  MISSING_REQUIRED=true
else
  VANITY_DOMAIN="${INPUT_DOMAIN}"
fi

if [ -z ${INPUT_ACCOUNT} ]; then
  echo "Use --account to define the account id of the tenant"
  MISSING_REQUIRED=true
else
  ACCOUNT_ID="${INPUT_ACCOUNT}"
fi

if [ -z ${INPUT_ALIAS} ]; then
  echo "Use --agentAlias to define the alias for the agent instance"
  MISSING_REQUIRED=true
else
  AGENT_ALIAS="${INPUT_ALIAS}"
fi

if [ ${MISSING_REQUIRED} ]; then
  exit 1
fi

# Create the token if necessary
if [ -z ${TENANT_TOKEN} ]; then
  TENANT_TOKEN=$(curl --silent --request POST "${IDENTITY_URL}/auth/realms/${VANITY_DOMAIN}/protocol/openid-connect/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'client_id=dai-svc-consumer' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode "password=${TENANT_PW}" \
    --data-urlencode "username=${TENANT_USER}" \
    --data-urlencode 'scope=openid dai-svc' \
    | jq -r .access_token)
fi

dumpAllAgentRuntimes() {
  echo "These are all the available agent runtime definitions:"
  curl --silent --request GET "${API_URL}/workload/v1/agent_runtimes" \
        --header "Authorization: Bearer ${TENANT_TOKEN}" \
        | jq '.agent_runtimes[] | {id, name, images}'
}

# If runtime ID wasn't supplied search by name or version to get the id
if [ -z ${AGENT_RUNTIME_ID} ]; then
  if [ ! -z ${SEARCH_NAME} ]; then
    # Search by runtime name
    RUNTIME_IDS=( $(curl --silent --request GET "${API_URL}/workload/v1/agent_runtimes?filter=name:${SEARCH_NAME}" \
      --header "Authorization: Bearer ${TENANT_TOKEN}" \
      | jq -r '.agent_runtimes[] | .id') )

    if [ ${#RUNTIME_IDS[@]} -eq 0 ]; then
      echo "No agent runtime definitions searching by name '${SEARCH_NAME}', an agent runtime may need to be created in the platform"
      dumpAllAgentRuntimes
      exit 1
    elif [ ${#RUNTIME_IDS[@]} -gt 1 ]; then
      echo "Too many agent runtime definitions found searching by name '${SEARCH_NAME}', use --version or --runtimeId instead to find the agent runtime to use"
      dumpAllAgentRuntimes
      exit 1
    else
      AGENT_RUNTIME_ID=${RUNTIME_IDS[0]}
    fi
  else
    # Search by agent runtime image version
    RUNTIME_IDS=( $(curl --silent --request GET "${API_URL}/workload/v1/agent_runtime_images?filter=name:release-remote-runner" \
      --header "Authorization: Bearer ${TENANT_TOKEN}" \
      | jq --arg tag "${SEARCH_VERSION}" \
        -r '.agent_runtime_images[] | select(.latest_tag == $tag) | .agent_runtime_id') )

    if [ ${#RUNTIME_IDS[@]} -eq 0 ]; then
      echo "No agent runtime definitions found using image version '${SEARCH_VERSION}', an agent runtime may need to be created in the platform"
      dumpAllAgentRuntimes
      exit 1
    elif [ ${#RUNTIME_IDS[@]} -gt 1 ]; then
      echo "Too many definitions found using image version '${SEARCH_VERSION}', use --runtimeName or --runtimeId instead to find the agent runtime to use"
      dumpAllAgentRuntimes
      exit 1
    else
      AGENT_RUNTIME_ID=${RUNTIME_IDS[0]}
    fi
  fi
fi

echo "Using agent runtime id ${AGENT_RUNTIME_ID}"
AGENT_RUNTIME=$(curl --silent --request GET "${API_URL}/workload/v1/agent_runtimes/${AGENT_RUNTIME_ID}" \
  --header "Authorization: Bearer ${TENANT_TOKEN}" \
  | jq -r '.agent_runtime | del(.k8s_template)')

if [ -z "${AGENT_RUNTIME}" ] || [ "${AGENT_RUNTIME}" == "null" ]; then
  echo "Agent runtime definition with id ${AGENT_RUNTIME_ID} can't be found"
  dumpAllAgentRuntimes
  exit 1
fi

echo "Agent runtime definition:"
echo "${AGENT_RUNTIME}" | jq
VARIABLES_JSON=$(echo "${AGENT_RUNTIME}" | jq '.variables | with_entries(select(.value | match("<.*>")))')
VARIABLE_NAMES=( $(echo "${VARIABLES_JSON}" | jq -r 'keys | .[]') )

echo "Variables that need to be defined in agent instance:"
for VARIABLE_NAME in "${VARIABLE_NAMES[@]}"; do
  if [ ! -z "${!VARIABLE_NAME}" ]; then
    echo "Defining ${VARIABLE_NAME} as value ${!VARIABLE_NAME}"
    VARIABLES_JSON=$(echo "${VARIABLES_JSON}" | jq --arg key "${VARIABLE_NAME}" --arg value "${!VARIABLE_NAME}" '.[$key] |= $value')
  else
    echo "Can't find value for script variable named: '${VARIABLE_NAME}'"
  fi
done

# Check VARIABLES_JSON to make sure all values are filled in
MISSING_VARS=$(echo "${VARIABLES_JSON}" | jq -r 'with_entries(select(.value | match("<.*>"))) | keys | .[]')
if [ ! -z ${MISSING_VARS} ]; then
  echo "There are variables needed in JSON definition that are not defined in this script:"
  echo "${MISSING_VARS}"
  exit 1
fi

AGENT_INSTANCE_POST_BODY=$(jq --null-input \
  --arg alias "${AGENT_ALIAS}" \
  --arg account "${ACCOUNT_ID}" \
  --arg runtime "${AGENT_RUNTIME_ID}" \
  --argjson variables "${VARIABLES_JSON}" \
  '{"account_id" : $account, "agent_id": $runtime, "alias": $alias, $variables}')

echo "Creating agent instance..."
RESPONSE=$(curl --silent --request POST "${API_URL}/workload/v1/agent_instances" \
  --header "Authorization: Bearer ${TENANT_TOKEN}" \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data "${AGENT_INSTANCE_POST_BODY}")

ERROR=$(echo "${RESPONSE}" | jq -r '.error.message')
if  [ -z "${ERROR}" ] || [ "${ERROR}" == "null" ]; then
  echo "${RESPONSE}" | jq -r '.agent_instance | del(.k8s_template)'
else
  echo "Creating agent instance failed, reason: ${ERROR}"
  echo "${RESPONSE}" | jq
  exit 1
fi

