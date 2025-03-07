# csf-webhook.sh
The following script will send the CSF firewall logs to a webhook. This script is called by /etc/aliases using pipe.

I'm using n8n.json to parse the JSON payload and send it to SMTP.

# Requirements
- jq
- curl

# Installation
1. Copy the script to /usr/local/sbin/csf-webhook.sh
2. Make the script executable: `chmod +x /usr/local/sbin/csf-webhook.sh`
3. Add the following line to /etc/aliases: `csf: "|/usr/local/sbin/csf-webhook.sh"`
4. Run `newaliases` to update the aliases database 
5. Updated /etc/csf/csf.conf to enable the LF_TRIGGER option: `LF_ALERT_TO = "csf"`
6. Restart LFD: `csf --lfd restart`

# Configuration
1. Create /usr/sbin/csf-webhook.conf with the following content:
```
WEBHOOK_URL="https://your-webhook-url"
```

# Setup n8n
1. Import the n8n.json workflow
2. Update the SMTP credentials
3. Start the workflow
4. Done!

