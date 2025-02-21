#!/bin/env bash
SCRIPT_DIR="$(dirname $0)"
SCRIPT_NAME="$(basename $0)"
LOG_FILE="$SCRIPT_DIR/monit-alert.log"

# =============================================================================
# -- Functions
# =============================================================================

# =====================================
# -- _log
# =====================================
_log () {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $SCRIPT_NAME - $1" >> $LOG_FILE
}

_load_config () {
    # Load environment variables from .env file confirm it exists and how many variables
    if [ -f "$SCRIPT_DIR/.env" ]; then
        _log "Loading environment variables from .env file"
        set -a
        source "$SCRIPT_DIR/.env"
        set +a
        _log "Environment variables loaded"
    else
        echo "Error: .env file not found"
        exit 1
    fi
}

# =====================================
# -- _send_gotify_alert $TITLE $MESSAGE $PRIORITY
# =====================================
_send_gotify_alert () {
    local TITLE=$1
    local MESSAGE=$2
    local PRIORITY=$3
    # Check if Gotify URL and token are set
    if [ -z "$GOTIFY_URL" ] || [ -z "$GOTIFY_TOKEN" ]; then
        _log "ERROR: Gotify URL or token not set"
        return 1
    fi

    _log "Gotify alert: $1 - $2 - $3"
    _log "Sending alert to Gotify - ${GOTIFY_URL}/message?token=${GOTIFY_TOKEN} -F title=$TITLE -F message=$MESSAGE -F priority=$PRIORITY"
    curl -X POST "${GOTIFY_URL}/message?token=${GOTIFY_TOKEN}" -F "title=$TITLE" -F "message=$MESSAGE" -F "priority=$PRIORITY"
    return $?
}

_send_webhook_alert () {
    # Send alert to Webhook
    # $1 - message
    # $2 - title
    # $3 - priority

    _log "Webhook alert: $1 - $2 - $3"
}

_send_email_alert () {
    # Send alert to Email
    # $1 - message
    # $2 - title
    # $3 - priority

    _log "Email alert: $1 - $2 - $3"
}

# =============================================================================
# -- Main
# =============================================================================

# Only log if not sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    _log "Monit alert triggered"
    _load_config
else
    _log "Monit alert sourced"
    _load_config
    return 0
fi

# Monit environment variables
MONIT_EVENT=$MONIT_EVENT
MONIT_SERVICE=$MONIT_SERVICE
MONIT_DESCRIPTION=$MONIT_DESCRIPTION
MONIT_DATE=$MONIT_DATE
MONIT_HOST=$MONIT_HOST  # Capturing hostname

TITLE="$MONIT_HOST - $MONIT_SERVICE - $MONIT_EVENT"
MESSAGE="$MONIT_DESCRIPTION - $MONIT_DATE - $MONIT_HOST"

SERVICES="$1"
SERVICES_ARRAY=()

# Break up the services
IFS='|' read -r -a SERVICES_ARRAY <<< "$SERVICES"

for SERVICE in "${SERVICES_ARRAY[@]}"
do
    case $SERVICE in
        gotify)
            _log "Sending alert to Gotify"
            _send_gotify_alert "$TITLE" "$MESSAGE" "5"
            ;;
        webhook)
            _log "Sending alert to Webhook"
            _send_webhook_alert "$MESSAGE" "$SERVICE_NAME" "$EVENT"
            ;;
        email)
            _log "Sending alert to Email"
            _send_email_alert "$MESSAGE" "$SERVICE_NAME" "$EVENT"
            ;;
        *)
            _log "Unknown service: $SERVICE"
            ;;
    esac
done
        