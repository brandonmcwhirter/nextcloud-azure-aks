#!/usr/bin/env bash

##
# Generates the commands necessary to download and configure New Relic
# monitoring.
#
# This is optional. This script only downloads and configures New Relic if the
# following environment variables are set:
#
# - NEW_RELIC_AGENT_URL
# - NEW_RELIC_KEY
# - NEW_RELIC_APP
#
# These variables are typically set via publish.profile in an overlay, and then this
# script is invoked automatically by `./rigger publish` within the overlay.
#
# @author Guy Elsmore-Paddock (guy@inveniem.com)
# @copyright Copyright (c) 2019-2022, Inveniem
# @license GNU AGPL version 3 or any later version
#
set -e
set -u

################################################################################
# Constants
################################################################################

outfile="./generated/setup_newrelic.sh"

script_path="${BASH_SOURCE[0]}"
script_name=$(basename "${script_path}")
script_dir="$( cd "$( dirname "${script_path}" )" >/dev/null 2>&1 && pwd )"

################################################################################
# Overridable Environment Variables
################################################################################
# All of the variables below can be specified on the command line to override
# them at run-time.

NEW_RELIC_AGENT_URL="${NEW_RELIC_AGENT_URL}"
NEW_RELIC_KEY="${NEW_RELIC_KEY}"
NEW_RELIC_APP="${NEW_RELIC_APP:-Nextcloud}"

################################################################################
# Main Script Body
################################################################################
cd "${script_dir}"

mkdir -p ./generated

###
# Start of Script Output
###
# Everything printed by the block below gets written to the "${outfile}".
{
  cat <<END
#!/usr/bin/env sh

# This file was generated by "${script_name}". DO NOT EDIT.

set -e
set -u

END

  if [[ "${NEW_RELIC_AGENT_URL:-}" != "" && \
        "${NEW_RELIC_KEY:-}" != "" && \
        "${NEW_RELIC_APP:-}" != "" ]]; then
    cat <<END
NEW_RELIC_AGENT_URL=\$(
    if [ -f "/etc/alpine-release" ]; then
        # Alpine Linux requires a special New Relic binary.
        echo "${NEW_RELIC_AGENT_URL}" | sed 's/-linux\.tar/-linux-musl\.tar/'
    else
        echo "${NEW_RELIC_AGENT_URL}"
    fi
)

echo "Downloading and unpacking NR binary from '\${NEW_RELIC_AGENT_URL}'..." >&2
curl -L "\${NEW_RELIC_AGENT_URL}" | tar -C /tmp -zx

export NR_INSTALL_USE_CP_NOT_LN=1
export NR_INSTALL_SILENT=1

/tmp/newrelic-php5-*/newrelic-install install
rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*

sed -i -e 's/\"REPLACE_WITH_REAL_KEY\"/\"${NEW_RELIC_KEY}\"/' \\
    -e 's/newrelic.appname = \"PHP Application\"/newrelic.appname = \"${NEW_RELIC_APP}\"/' \\
    /usr/local/etc/php/conf.d/newrelic.ini
END
    else
        echo "# New Relic Monitoring disabled in publish.profile of overlay."
    fi
} > "${outfile}"
###
# End of Script Output
###
