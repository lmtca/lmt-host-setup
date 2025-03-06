#!/bin/bash
# -- Variables
OUTPUT=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATE_START="$(date)"

# -- Configuration
LOG_FILE_SIZE=50MB # 10MB
LOG_ROTATE=5
LOG_FILE="$SCRIPT_DIR/csf-webhook.log"
DEBUG="0"

# -- Source the configuration file
if [ -f "$SCRIPT_DIR/csf-webhook.conf" ]; then
    source "$SCRIPT_DIR/csf-webhook.conf"
fi

# ==============================================================================
# -- Functions
# ==============================================================================
# =====================================
# -- Debug function
# =====================================
function _debug () {
    [[ "$DEBUG" == "1" ]] && { OUTPUT+="${*}\n";}
}

function _log () {
    # Add to $OUTPUT
    OUTPUT+="${*}\n"
}

# =====================================
# -- check_log_size
# =====================================
check_log_size () {
    # Convert MB to bytes
    local size_in_bytes
    if [[ $LOG_FILE_SIZE =~ ([0-9]+)MB ]]; then
        size_in_bytes=$((${BASH_REMATCH[1]} * 1024 * 1024))
    else
        # Default to 10MB if parsing fails
        size_in_bytes=$((10 * 1024 * 1024))
    fi
    
    # Rotate log, and then gzip the rotated log
    if [ -f "$LOG_FILE" ] && [ "$(stat -c %s "$LOG_FILE")" -gt "$size_in_bytes" ]; then
        # Remove the oldest log if it exists
        if [ -f "$LOG_FILE.$LOG_ROTATE.gz" ]; then
            rm "$LOG_FILE.$LOG_ROTATE.gz"
        fi
        
        # Rotate existing logs (compressed ones)
        for i in $(seq $((LOG_ROTATE-1)) -1 1); do
            if [ -f "$LOG_FILE.$i.gz" ]; then
                mv "$LOG_FILE.$i.gz" "$LOG_FILE.$((i+1)).gz"
            fi
        done
        
        # Move current log to .1 and compress it
        mv "$LOG_FILE" "$LOG_FILE.1"
        gzip -f "$LOG_FILE.1"
    fi
}

# =====================================
# -- process_email
# =====================================
process_email () {
    EMAIL="${*}"
    # Extract sender
    CSF_SENDER=$(echo "$EMAIL" | grep -oP '(?<=From: ).*')
    # Extract subject
    CSF_SUBJECT=$(echo "$EMAIL" | grep -oP '(?<=Subject: ).*')
}

# ==============================================================================
# -- Arguments
# ==============================================================================
while getopts ":dtp" opt; do
    case $opt in
        p)
            MODE="test-data"        
            ;;
        t)
            MODE="test"
            ;;
        d)
            DEBUG="1"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done


# ==============================================================================
# -- Main
# ==============================================================================

# -- Check if WEBHOOK_URL is set
if [ -z "$WEBHOOK_URL" ]; then
    echo "WEBHOOK_URL is not set. Please set it in the configuration file."
    exit 1
fi

# -- Check log size
check_log_size

# -- Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it."
    exit 1
fi

# -- Check if test mode is enabled
if [ "$MODE" == "test" ]; then
    if [ ! -f "$SCRIPT_DIR/test-email.txt" ]; then
        echo "Test email file not found. Please create a $SCRIPT_DIR/test-email.txt file in the same directory."
        exit 1
    fi
    CSF_CONTENT=$(cat $SCRIPT_DIR/test-email.txt)
    echo "Test mode enabled."
    echo "Test email content:"
    echo "==================================================="
    echo "$CSF_CONTENT"
    echo "==================================================="
    process_email "$CSF_CONTENT"
    echo "Sender: $CSF_SENDER"
    echo "Subject: $CSF_SUBJECT"
    echo "Body: $CSF_CONTENT"
    exit 0
elif [ "$MODE" == "test-data" ]; then
    if [ ! -f "$SCRIPT_DIR/test-email.txt" ]; then
        echo "Test email file not found. Please create a $SCRIPT_DIR/test-email.txt file in the same directory."
        exit 1
    fi
    CSF_CONTENT=$(cat $SCRIPT_DIR/test-email.txt)
    process_email "$CSF_CONTENT"
else
    CSF_CONTENT=$(cat)
    process_email "$CSF_CONTENT"
fi

_log "==================================================================="
_log "Started at $DATE_START"
# Read the email from standard input (where Postfix will pipe it)

_log "Sending data to $WEBHOOK_URL"
_log "---------------------------------------------------"
_log "Sender: $CSF_SENDER"
_log "---------------------------------------------------"
_log "Subject: $CSF_SUBJECT"
_log "---------------------------------------------------"
_log "Body: $CSF_CONTENT"
_log "---------------------------------------------------"

# Prepare the data for the webhook (e.g., as JSON)
PAYLOAD=$(jq -n \
          --arg sender "$CSF_SENDER" \
          --arg subject "$CSF_SUBJECT" \
          --arg body "$CSF_CONTENT" \
          '{sender: $sender, subject: $subject, body: $body}')

_log "Payload: $PAYLOAD"

# Send the data to your webhook
CURL_OUTPUT=$(curl -s -X POST \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD" \
     "$WEBHOOK_URL")

_log "$CURL_OUTPUT"
DATE_END="$(date)"
_log "Finished at $DATE_END"
_log "==================================================================="

echo -e "$OUTPUT" >> "$LOG_FILE"
[[ $DEBUG == "1" ]] && echo -e "$OUTPUT"