#!/bin/env bash
# -- Test monit-alert.sh script
SCRIPT_DIR="$(dirname $0)"
SCRIPT_NAME="$(basename $0)"
source $SCRIPT_DIR/monit-alert.sh

# =============================================================================
# -- Functions
# =============================================================================
_usage () {
    echo "Usage: $0 <service>"
    exit 1
}

# =============================================================================
# -- Main
# =============================================================================
_log "Test script started"
if [ $# -ne 1 ]; then
    _usage
fi

SERVICE="$1"

# Monit environment variables
MONIT_EVENT="Resource limit matched"
MONIT_SERVICE="nginx"
MONIT_DESCRIPTION="memory usage of 90.0% matches resource limit [mem usage>90.0%]"
MONIT_DATE="2021-09-01 12:00:00"
MONIT_HOST="localhost"

TITLE="$MONIT_HOST - $MONIT_SERVICE - $MONIT_EVENT"
MESSAGE="$MONIT_DESCRIPTION - $MONIT_DATE - $MONIT_HOST"

case $SERVICE in
    gotify)
        _log "Sending test alert to Gotify"
        _send_gotify_alert "$TITLE" "$MESSAGE" "$EVENT" "5"
        ;;
    webhook)
        _log "Sending test alert to Webhook"
        _send_webhook_alert "$MESSAGE" "$SERVICE_NAME" "$EVENT"
        ;;
    email)
        _log "Sending test alert to Email"
        _send_email_alert "$MESSAGE" "$SERVICE_NAME" "$EVENT"
        ;;
    *)
        _log "Unknown service: $SERVICE"
        ;;
esac


