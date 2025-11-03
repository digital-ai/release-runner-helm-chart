#!/usr/bin/env bash

if [ -z "$RELEASE_REGISTRY" ]; then
  echo "The '\$RELEASE_REGISTRY environment variable is not set."
  exit 1
fi
if [ -z "$RELEASE_EXPLICIT" ]; then
  echo "The '\$RELEASE_EXPLICIT environment variable is not set."
  exit 1
fi

helm package . -u --version $RELEASE_EXPLICIT
helm push  runner-${RELEASE_EXPLICIT}.tgz oci://docker.io/${RELEASE_REGISTRY}

rm runner-${RELEASE_EXPLICIT}.tgz