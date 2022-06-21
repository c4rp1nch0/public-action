#!/bin/bash

/bin/echo "::group:: Getting the SHAs"

/bin/echo "Trigger event: ${GITHUB_EVENT_NAME}" 

if [ "${GITHUB_EVENT_NAME}" == "pull_request" ]; then 
    BASE_SHA="$(/usr/bin/jq -r '.pull_request.base.sha' < "${GITHUB_EVENT_PATH}" | /bin/grep -Po "[a-f0-9]{40}")"
    HEAD_SHA="$(echo "${GITHUB_SHA}" | /bin/grep -Po "[a-f0-9]{40}")" 
else 
    BASE_SHA="$(/usr/bin/jq -r '.before' < "${GITHUB_EVENT_PATH}" | /bin/grep -Po "[a-f0-9]{40}")"
    HEAD_SHA="$(/usr/bin/jq -r '.after' < "${GITHUB_EVENT_PATH}" | /bin/grep -Po "[a-f0-9]{40}")"
fi

[ -z "${BASE_SHA}" ] \
    && /bin/echo "::error:: Couldn't get the BASE SHA." && exit 1

[ -z "${HEAD_SHA}" ] \
    && /bin/echo "::error:: Couldn't get the HEAD SHA." && exit 1

/bin/echo "BASE SHA: ${BASE_SHA}"
/bin/echo "HEAD SHA: ${HEAD_SHA}"

/bin/echo "::endgroup::"


/bin/echo "::group:: Changing working directory..."

pushd "${GITHUB_WORKSPACE}" >/dev/null || \
    (/bin/echo "::error:: Couldn't change the working directory to '${GITHUB_WORKSPACE}'" && exit 1)

WORKSPACE_PATH="$(/usr/bin/readlink -fn "${INPUT_PATH}")"

popd >/dev/null || \
    (/bin/echo "Couldn't restore the working directory" && exit 1)

[ ! -d "${WORKSPACE_PATH}" ] && \
    (/bin/echo "::error:: Couldn't resolve the working directory '${WORKSPACE_PATH}'" && exit 1 )

pushd "${WORKSPACE_PATH}" >/dev/null || \
    (/bin/echo "::error:: Couldn't change the working directory to '${WORKSPACE_PATH}'" && exit 1)

/bin/echo "::endgroup::"

/bin/echo "::group:: Getting tinted files" 

# Get tinted files and join them with xargs in a single line
TINTED_FILES="$(/usr/bin/git diff --name-only "${BASE_SHA}" "${HEAD_SHA}" | xargs)"

[ -z "${TINTED_FILES}" ] \
    && /bin/echo "::error:: Couldn't get the tinted files." && exit 1

/bin/echo "Tinted files:"
/bin/echo "::set-output name=tinted-files::${TINTED_FILES}"

for tinted in ${TINTED_FILES[@]}; do
    /bin/echo "* $tinted"
done

/bin/echo "::endgroup::" 


