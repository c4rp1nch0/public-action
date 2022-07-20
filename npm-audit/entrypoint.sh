#!/bin/bash

set -uo -pipefail

/bin/echo "NPM version: $(/usr/local/bin/npm --version)"
/bin/echo "Reviewdog version: $(/usr/local/bin/reviewdog -version)"

/bin/echo "::group:: Checking files and paths..."

PROJECT_PATH="$(readlink -fn "${GITHUB_WORKSPACE}/${INPUT_NPMA_PATH}")"

pushd "${PROJECT_PATH}" >/dev/null \
    || (/bin/echo "Couldn't change the working directory to '${PROJECT_PATH}'" \
    && exit 1)

PACKAGE_JSON="$(readlink -fn "${PROJECT_PATH}/package.json")"

[ ! -f "${PACKAGE_JSON}" ] \
    && /bin/echo "Couldn't find the package.json file in '${PACKAGE_JSON}'" \
    && exit 1

PACKAGE_LOCK="$(readlink -fn "${PROJECT_PATH}/package-lock.json")"

if [ ! -f "${PACKAGE_LOCK}" ]; then 
    /bin/echo "::warning:: Couldn't find the package-lock.json file in '${PACKAGE_LOCK}'" 
    /bin/echo "Running 'npm install --package-lock-only to generate it..."
    /usr/local/bin/npm install --no-progress --package-lock-only  || \
        (/bin/echo "::error:: Couldn't generate the package-lock.json" \
        && exit 1)
fi

/bin/echo "::endgroup::"

/bin/echo "::group:: Running NPM AUDIT"

AUDIT_OUT_FILE="$(/bin/mktemp -d)"
if [ -z "${INPUT_NPMA_FLAGS}" ]; then
    /usr/local/bin/npm audit --json > "${AUDIT_OUT_FILE}" 
else
    IFS="${INPUT_NPMA_FLAGS_SEPARATOR:- }" read -r -a AUDIT_FLAGS <<< "${INPUT_NPMA_FLAGS}"
    /usr/local/bin/npm audit --json "${AUDIT_FLAGS[@]}" > "${AUDIT_OUT_FILE}" 
fi

/bin/echo "::endgroup::" 

/bin/echo "::group:: Converting to RDJSON"

RDJSON_OUT="$(/bin/mktemp)"
/usr/local/bin/npm_audit_to_rdjson --audit-file "${AUDIT_OUT_FILE}" \
                                   --package-json "${PACKAGE_JSON}" \
                                   --output "${RDJSON_OUT}" \
    || (/bin/echo "Error while converting the npm-audit output to rdjson" \
        && exit 1) 

/bin/echo "::endgroup::" 


/bin/echo "::group:: Running REVIEWDOG" 

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_RD_GH_TOKEN}"

pushd "${GITHUB_WORKSPACE}" >/dev/null \
    || (/bin/echo "Couldn't change the working directory to '${GITHUB_WORKSPACE}'" && exit 1)

if [ -z "${INPUT_RD_FLAGS}" ]; then
    /usr/local/bin/reviewdog \
        -f="${INPUT_RD_FORMAT}" \
        -name="${INPUT_RD_NAME}" \
        -filter-mode="${INPUT_RD_FILTER_MODE}" \
        -reporter="${INPUT_RD_REPORTER:-github-pr-review}" \
        -level="${INPUT_RD_LEVEL}" \
        -fail-on-error="${INPUT_RD_FAIL_ON_ERROR}" < "${RDJSON_OUT}"
else
    IFS="${INPUT_RD_FLAGS_SEPARATOR:- }" read -r -a REVIEWDOG_FLAGS <<< "${INPUT_RD_FLAGS}"

    /usr/local/bin/reviewdog \
        -f="${INPUT_RD_FORMAT}" \
        -name="${INPUT_RD_NAME}" \
        -filter-mode="${INPUT_RD_FILTER_MODE}" \
        -reporter="${INPUT_RD_REPORTER:-github-pr-review}" \
        -level="${INPUT_RD_LEVEL}" \
        -fail-on-error="${INPUT_RD_FAIL_ON_ERROR}" \
        "${REVIEWDOG_FLAGS[@]}" < "${RDJSON_OUT}"
fi

rd_exit_code=$?

echo '::endgroup::'

exit $rd_exit_code
