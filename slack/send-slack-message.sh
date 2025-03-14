#!/bin/env bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <slack_webhook_url> <channel>"
  exit 1
fi

WEBHOOK_URL=$1
CHANNEL=$2
MESSAGE="Hello from the shell script!"

# Create JSON payload
payload=$(cat <<EOF
{
  "channel": "$CHANNEL",
  "username": "ShellBot",
  "text": "$MESSAGE",
  "icon_emoji": ":robot_face:"
}
EOF
)

# Send message to Slack using curl
curl -X POST -H 'Content-type: application/json' --data "$payload" "$WEBHOOK_URL"
