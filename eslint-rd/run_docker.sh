#!/bin/bash
set -x
docker run --rm  \
    -v "${GITHUB_ACTION_PATH}/entrypoint.sh":"/entrypoint.sh" \
    -v "${GITHUB_WORKSPACE}":"/github/workspace" \
    -v "${GITHUB_ACTION_PATH}/configs":"/home/node/scan/configs" \
    -v "${GITHUB_EVENT_PATH}":"/github/workflow/event.json" \
    -e GITHUB_WORKSPACE="/github/workspace" \
    -e REVIEWDOG_GITHUB_API_TOKEN="${INPUT_RD_GH_TOKEN}" \
    -e GITHUB_EVENT_PATH="/github/workflow/event.json" \
    -e CI=true \
    -e GITHUB_ACTIONS=true \
    -e GITHUB_ACTION \
    -e GITHUB_API_URL \
    -e GITHUB_EVENT_NAME \
    -e INPUT_ESL_EXT \
    -e INPUT_ESL_CONFIG_NAME \
    -e INPUT_ESL_FORMAT \
    -e INPUT_ESL_PATHS \
    -e INPUT_ESL_FLAGS \
    -e INPUT_RD_FORMAT \
    -e INPUT_RD_REPORTER \
    -e INPUT_RD_LEVEL \
    -e INPUT_RD_FILTER_MODE \
    -e INPUT_RD_FAIL_ON_ERROR \
    -e INPUT_RD_FLAGS \
    -e INPUT_RD_NAME \
    -e INPUT_RD_GH_TOKEN \
    --entrypoint "/entrypoint.sh" \
    c4rp1nch0/security-tools-eslint:latest

