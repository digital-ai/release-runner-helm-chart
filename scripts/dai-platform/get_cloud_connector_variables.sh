#!/bin/bash

while [[ $# -gt 0 ]]; do
  ARG_COUNT=$#
  case $1 in
    --workspace)
      WORKSPACE_ROOT="$2"
      shift # past argument
      shift # past value
      ;;
    --verbose)
      VERBOSE=true
      shift
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

if [ ! -z ${VERBOSE} ]; then
  set -x
fi

if [ -z ${WORKSPACE_ROOT} ]; then
  WORKSPACE_ROOT=".."
fi

CLOUD_CONNECTOR_YAML=${WORKSPACE_ROOT}/values-cloud-connector.yaml
DEFAULT_YAML=${WORKSPACE_ROOT}/values.yaml

# Variable names to ignore, these are built into cloud connector
EXCLUDES=(
  "AGENT_IMAGE_release-remote-runner"
  "DAI_NAMESPACE"
)

EXCLUDE_VARS=""
for exclude in ${EXCLUDES[*]}; do
  if [ ! -z ${EXCLUDE_VARS} ]; then
    EXCLUDE_VARS="${EXCLUDE_VARS}\|"
  fi
  EXCLUDE_VARS="${EXCLUDE_VARS}${exclude}"
done

# Find all the variables defined in the cloud connector yaml file that the client defines
VARIABLES=$(grep "\${" ${CLOUD_CONNECTOR_YAML} | awk -F '"' '{print $2}' | sort | uniq | grep -v ${EXCLUDE_VARS})

VARIABLE_JSON='{}'
for variable in ${VARIABLES}; do
  # Build string to find full paths to property that have the variable as the value
  yq_eval=$(echo '.. | select( . == "'${variable}'" ) | (path | join("."))')

  # Find the full paths to property in the cloud-connector yaml for the variable
  property=$(yq eval "${yq_eval}" ${CLOUD_CONNECTOR_YAML})

  # Look for the value used in the same property in the default yaml file to use a
  # default value in cloud connector
  default_value=$(yq ".${property}" ${DEFAULT_YAML})

  # Strip off braces from the variable to use as a property name in JSON
  key=$(echo ${variable} | sed -e 's/\${\(.*\)}/\1/')

  # If a value wasn't found in the default yaml file assume the client must define the value when creating
  # an agent instance so wrap name in angle braces to use as a value
  if [ -z ${default_value} ]; then
    default_value="<${key}>"
  fi
  VARIABLE_JSON=$(jq ". += { ${key} : \"${default_value}\" }" <<< ${VARIABLE_JSON})
done

echo ${VARIABLE_JSON}
