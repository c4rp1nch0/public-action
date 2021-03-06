#!/bin/bash
set -x


/bin/echo "Eslint version: $(/usr/local/bin/eslint --version)"
/bin/echo "Reviewdog version: $(/usr/local/bin/reviewdog -version)"

SCAN_PATH="/home/node/scan"

/bin/echo "::group:: Checking eslintrc"

CONFIGS_FOLDER="/home/node/scan/configs"

[ ! -d "${CONFIGS_FOLDER}" ] \
    && /bin/echo "::error:: Couldn't find the 'configs' folder '${CONFIGS_FOLDER}'" && exit 1

pushd "${CONFIGS_FOLDER}" >/dev/null \
    || (/bin/echo "::error:: Couldn't change the working directory to '${CONFIGS_FOLDER}'" && exit 1)


ESLINTRC_PATH="$(/usr/bin/readlink -fn "${INPUT_ESL_CONFIG_NAME}")"

if [ ! -f "${ESLINTRC_PATH}" ]; then
    /bin/echo "::warning:: Couldn't find the eslint config file '${ESLINTRC_PATH}'"
    /bin/echo "::warning:: Falling back to 'default.json'..."

    ESLINTRC_PATH="$(/usr/bin/readlink -fn 'default.json')"

    [ ! -f "${ESLINTRC_PATH}" ] \
        && /bin/echo "::error:: Couldn't find the eslint config file '${ESLINTRC_PATH}'" && exit 1
fi

/bin/echo "Selected eslintrc: '${ESLINTRC_PATH}'" 

(/bin/cp "${ESLINTRC_PATH}" "${SCAN_PATH}/eslintrc" \
    && /bin/echo "'${ESLINTRC_PATH}' copied to '${SCAN_PATH}/eslinrc'") \
    || (/bin/echo "::error:: Couldn't copy the file '${ESLINTRC_PATH}' to '${SCAN_PATH}'" && exit 1)

popd >/dev/null || (/bin/echo "Couldn't restore the working directory" && exit 1)

/bin/echo "::endgroup::"


/bin/echo "::group:: Getting the absolute paths to scan" 

pushd "${GITHUB_WORKSPACE}" >/dev/null \
    || (/bin/echo "Couldn't change the working directory to '${GITHUB_WORKSPACE}'" && exit 1)

# Convert INPUT_ESL_PATH to an array of paths
IFS="${INPUT_ESL_PATHS_SEPARATOR:- }" read -r -a TMP_ESLINT_PATHS <<< "${INPUT_ESL_PATHS}"

# As we have to lunch the eslint scan withing the $SCAN_PATH folder, we'll have to transform
# the relativate paths comming from $TMP_ESLINT_PATHS to their absolute equivalent. 
FILES_TO_SCAN=()
/bin/echo 'Paths to scan:'
for path in "${TMP_ESLINT_PATHS[@]}"; do
    abs_path=$(/usr/bin/readlink -f "$path")
    if [ -z "${abs_path}" ]; then 
        /bin/echo "::warning:: Couldn't resolve the abs path of '${abs_path}'. This will not be scanned."
    else
        /bin/echo "* Changed '${path}' to '${abs_path}'"
        FILES_TO_SCAN+=("${abs_path}")
    fi
done

popd >/dev/null || (/bin/echo "Couldn't restore the working directory" && exit 1)

/bin/echo "::endgroup::"

/bin/echo "::group:: Running ESLINT"  

pushd "${SCAN_PATH}" >/dev/null \
    || (/bin/echo "coudln't change directory to ${SCAN_PATH}" && exit 1)

ESLINT_OUT="$(/bin/mktemp)"

# Convert eslint flags to an array  
IFS="${INPUT_ESL_FLAGS_SEPARATOR:- }" read -r -a ESLINT_FLAGS <<< "${INPUT_ESL_FLAGS}" \
    || (/bin/echo "::error:: Couldn't conver eslint flags to an array" && exit 1)

/usr/local/bin/eslint \
    --config '/home/node/scan/eslintrc' \
    --ext "${INPUT_ESL_EXT}" \
    --format "${INPUT_ESL_FORMAT}" \
    --output-file "${ESLINT_OUT}" \
    "${ESLINT_FLAGS[@]}" \
    "${FILES_TO_SCAN[@]}"

/bin/echo "eslint output:"
/bin/cat "${ESLINT_OUT}"

/bin/echo "::endgroup::" 


echo '::group:: Running REVIEWDOG'

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_RD_GH_TOKEN}"

pushd "${GITHUB_WORKSPACE}" >/dev/null \
    || (/bin/echo "Couldn't change the working directory to '${GITHUB_WORKSPACE}'" && exit 1)


IFS="${INPUT_RD_FLAGS_SEPARATOR:- }" read -r -a RD_FLAGS <<< "${INPUT_RD_FLAGS}"

/usr/local/bin/reviewdog \
    -f="${INPUT_RD_FORMAT}" \
    -name="${INPUT_RD_NAME}" \
    -filter-mode="${INPUT_RD_FILTER_MODE}" \
    -reporter="${INPUT_RD_REPORTER:-github-pr-review}" \
    -level="${INPUT_RD_LEVEL}" \
    -fail-on-error="${INPUT_RD_FAIL_ON_ERROR}" \
    "${RD_FLAGS[@]}" < "${ESLINT_OUT}" 

rd_exit_code=$?

echo '::endgroup::'

exit $rd_exit_code

