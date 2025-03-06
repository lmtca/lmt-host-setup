#!/bin/bash
# -- Variables
EMAIL_CONTENT="$(cat)"
OUTPUT=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATE_START="$(date)"

# -- Configuration
LOG_FILE_SIZE=50MB # 10MB
LOG_ROTATE=5
LOG_FILE="$SCRIPT_DIR/csf-webhook.log"
DEBUG="0"
WEBHOOK_URL=""

# ==============================================================================
# -- Functions
# ==============================================================================
# =====================================
# -- Debug function
# =====================================
function debug () {
    [[ "$DEBUG" == "1" ]] && { OUTPUT+="$@\n";}
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

debug "==================================================================="
debug "Started at $DATE_START"
# Read the email from standard input (where Postfix will pipe it)

debug "Sending data to $WEBHOOK_URL"
debug "$CSF_CONTENT"

# Extract relevant information from the email (customize as needed)
sender=$(echo "$email" | grep -oP 'From: \K.*')
subject=$(echo "$email" | grep -oP 'Subject: \K.*')
body=$(echo "$email" | sed '1,/^$/d')  # Extract body after headers

# Prepare the data for the webhook (e.g., as JSON)
payload=$(jq -n \
          --arg sender "$sender" \
          --arg subject "$subject" \
          --arg body "$body" \
          '{sender: $sender, subject: $subject, body: $body}')

debug "Payload: $payload"

# Send the data to your webhook
CURL_OUTPUT=$(curl -s -X POST \
     -H "Content-Type: application/json" \
     -d "$payload" \
     "$WEBHOOK_URL")

debug "$CURL_OUTPUT"
DATE_END="$(date)"
debug "Finished at $DATE_END"
debug "==================================================================="
echo -e "$OUTPUT" >> $LOG_FILE
