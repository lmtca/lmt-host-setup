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

_debug () {
    if [ "$DEBUG" == "true" ]; then
        _log "DEBUG: $1"
    fi
}

_load_config () {
    # Load environment variables from .env file confirm it exists and how many variables
    if [ -f "$SCRIPT_DIR/.env" ]; then
        _log "Loading environment variables from .env file"
        set -a
        source "$SCRIPT_DIR/.env"
        set +a
        _debug "Environment variables loaded from ${SCRIPT_DIR}/.env file - SERVICES: ${SERVICES[@]}"
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
    curl -X POST "${GOTIFY_URL}/message?token=${GOTIFY_TOKEN}" -F "title=$TITLE" -F "message=$MESSAGE" -F "priority=$PRIORITY" -s -o /dev/null -w "%{http_code}" | grep -q "200" && return 0 || return $?
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

# Check if alert_type is passed via $1
if [ -n "$1" ]; then
    _log "Alert type passed via argument - $1"
    EVENT=$1
else
    _log "Alert type not passed via argument - Using MONIT_EVENT: $MONIT_EVENT"
    EVENT=$MONIT_EVENT
fi

# Monit environment variables
_debug "Monit environment variables - MONIT_EVENT: $EVENT, MONIT_SERVICE: $MONIT_SERVICE, MONIT_DESCRIPTION: $MONIT_DESCRIPTION, MONIT_DATE: $MONIT_DATE, MONIT_HOST: $MONIT_HOST"
MONIT_SERVICE=$MONIT_SERVICE
MONIT_DESCRIPTION=$MONIT_DESCRIPTION
MONIT_DATE=$MONIT_DATE
MONIT_HOST=$MONIT_HOST  # Capturing hostname

TITLE="$MONIT_HOST - $MONIT_SERVICE - $$EVENT"
MESSAGE="$MONIT_DESCRIPTION - $MONIT_DATE - $MONIT_HOST"

# Check if $SERVICES=() is not empty
if [ -z "$SERVICES" ]; then
    _log "No services to alert - SERVICES: ${SERVICES[@]} - Exiting"
    exit 0
else
    _log "Services to alert: ${SERVICES[@]}"
fi

for SERVICE in "${SERVICES[@]}"; do
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
            _log "Unknown service: $SERVICE or not enabled"
            ;;
    esac
done
_log "Monit alert completed"