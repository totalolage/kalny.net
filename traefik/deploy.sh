#!/usr/bin/env bash

## This script is used to deploy the traefik configuration
## without downtime by rotateing the config files.

# Check dependencies
command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is required but it's not installed. Aborting."; exit 1; }
command -v yq >/dev/null 2>&1 || { echo >&2 "yq is required but it's not installed. Aborting."; exit 1; }

# cd to the directory containing this script
cd "$(dirname "${BASH_SOURCE[0]}")"

# Check that the required files exist
[[ -f config.dynamic.yaml ]] || { echo >&2 "config.dynamic.yaml is required but it's not found. Aborting."; exit 1; }
[[ -f config.static.yaml ]] || { echo >&2 "config.static.yaml is required but it's not found. Aborting."; exit 1; }
[[ -f compose.yaml ]] || { echo >&2 "compose.yaml is required but it's not found. Aborting."; exit 1; }

# Get the hash of the config files
DYNAMIC_CONFIG_HASH=$(md5 -q config.dynamic.yaml)
STATIC_CONFIG_HASH=$(md5 -q config.static.yaml)

DYNAMIC_CONFIG_HASH_MATCHER="dynamic_config_([a-z0-9]{${#DYNAMIC_CONFIG_HASH}})"
STATIC_CONFIG_HASH_MATCHER="static_config_([a-z0-9]{${#STATIC_CONFIG_HASH}})"

# Get the names of the currently deployed docker configs from the compose file
CURRENT_CONFIG_NAMES=$(yq '.configs|keys|.[]' compose.yaml)
[[ -n "$CURRENT_CONFIG_NAMES" ]] || { echo >&2 "No configs found in compose.yaml. Aborting."; exit 1; }
CURRENT_DYNAMIC_CONFIG_NAME=$(grep -Eo "$DYNAMIC_CONFIG_HASH_MATCHER"<<< $CURRENT_CONFIG_NAMES | head -n 1)
[[ -n "$CURRENT_DYNAMIC_CONFIG_NAME" ]] || { echo >&2 "No dynamic config found in compose.yaml. Aborting."; exit 1; }
CURRENT_STATIC_CONFIG_NAME=$(grep -Eo "$STATIC_CONFIG_HASH_MATCHER"<<< $CURRENT_CONFIG_NAMES | head -n 1)
[[ -n "$CURRENT_STATIC_CONFIG_NAME" ]] || { echo >&2 "No static config found in compose.yaml. Aborting."; exit 1; }
CURRENT_DYNAMIC_CONFIG_HASH=$(sed -En "s/^$DYNAMIC_CONFIG_HASH_MATCHER$/\1/p" <<< $CURRENT_DYNAMIC_CONFIG_NAME)
CURRENT_STATIC_CONFIG_HASH=$(sed -En "s/^$STATIC_CONFIG_HASH_MATCHER$/\1/p" <<< $CURRENT_STATIC_CONFIG_NAME)

# If the hashes no longer match, replace the old config values with the new ones
if [[ "$CURRENT_DYNAMIC_CONFIG_HASH" != "$DYNAMIC_CONFIG_HASH" ]]; then
  echo "Updating dynamic config hash from $CURRENT_DYNAMIC_CONFIG_HASH to $DYNAMIC_CONFIG_HASH"
  sed -i "s/$CURRENT_DYNAMIC_CONFIG_HASH/$DYNAMIC_CONFIG_HASH/g" compose.yaml
fi
if [[ "$CURRENT_STATIC_CONFIG_HASH" != "$STATIC_CONFIG_HASH" ]]; then
  echo "Updating static config hash from $CURRENT_STATIC_CONFIG_HASH to $STATIC_CONFIG_HASH"
  sed -i "s/$CURRENT_STATIC_CONFIG_HASH/$STATIC_CONFIG_HASH/g" compose.yaml
fi

docker stack deploy -c compose.yaml traefik

# # Debug print everything
# echo "DYNAMIC_CONFIG_HASH: $DYNAMIC_CONFIG_HASH"
# echo "STATIC_CONFIG_HASH: $STATIC_CONFIG_HASH"
# echo "DYNAMIC_CONFIG_HASH_MATCHER: $DYNAMIC_CONFIG_HASH_MATCHER"
# echo "STATIC_CONFIG_HASH_MATCHER: $STATIC_CONFIG_HASH_MATCHER"
# echo "CURRENT_CONFIG_NAMES: $CURRENT_CONFIG_NAMES"
# echo "CURRENT_DYNAMIC_CONFIG_NAME: $CURRENT_DYNAMIC_CONFIG_NAME"
# echo "CURRENT_STATIC_CONFIG_NAME: $CURRENT_STATIC_CONFIG_NAME"
# echo "CURRENT_DYNAMIC_CONFIG_HASH: $CURRENT_DYNAMIC_CONFIG_HASH"
# echo "CURRENT_STATIC_CONFIG_HASH: $CURRENT_STATIC_CONFIG_HASH"
