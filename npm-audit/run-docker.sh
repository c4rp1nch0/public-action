#!/bin/bash

docker run --rm  \
    -v "${GITHUB_ACTION_PATH}/entrypoint.sh":"/entrypoint.sh" \
    -v "${GITHUB_ACTION_PATH}/npm_audit_rdjson":"/usr/local/bin/npm_audit_rdjson" \
    -v "${GITHUB_WORKSPACE}":"/github/workspace" \
    -v "${GITHUB_EVENT_PATH}":"/github/workflow/event.json" \
    -e GITHUB_WORKSPACE="/github/workspace" \
    -e GITHUB_EVENT_PATH="/github/workflow/event.json" \
    -e REVIEWDOG_GITHUB_API_TOKEN="${INPUT_RD_GH_TOKEN}" \
    -e CI=true \
    -e GITHUB_ACTIONS=true \
    -e GITHUB_ACTION \
    -e GITHUB_API_URL \
    -e GITHUB_EVENT_NAME \
    -e INPUT_NPMA_PATH \
    -e INPUT_NPMA_FLAGS \
    -e INPUT_NPMA_FLAGS_SEPARATOR \
    -e INPUT_RD_FORMAT \
    -e INPUT_RD_REPORTER \
    -e INPUT_RD_LEVEL \
    -e INPUT_RD_FILTER_MODE \
    -e INPUT_RD_FAIL_ON_ERROR \
    -e INPUT_RD_FLAGS \
    -e INPUT_RD_FLAGS_SEPARATOR \
    -e INPUT_RD_NAME \
    -e INPUT_RD_GH_TOKEN \
    -e INPUT_DOCKER_REGISTRY \
    --entrypoint "/entrypoint.sh" \
    "c4rp1nch0/security-tools-eslint:latest"

