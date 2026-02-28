import json
import gzip
import base64
import os
import urllib3


http = urllib3.PoolManager()

def lambda_handler(event, context):

    slack_url = os.environ['SLACK_WEBHOOK_URL']
    
    cw_data = event['awslogs']['data']
    compressed_payload = base64.b64decode(cw_data)
    uncompressed_payload = gzip.decompress(compressed_payload)
    payload = json.loads(uncompressed_payload)

    for log_event in payload['logEvents']:
        
        msg = {
            "text": f"🚨 *AWS Alert - Flask App Error* 🚨\n\n"
                    f"*Log Group:* `{payload['logGroup']}`\n"
                    f"*Log Stream:* `{payload['logStream']}`\n"
                    f"*Message:* ```{log_event['message']}```"
        }
        
        encoded_msg = json.dumps(msg).encode('utf-8')
        
        resp = http.request('POST', slack_url, body=encoded_msg, headers={'Content-Type': 'application/json'})
        
        print(f"Slack response status: {resp.status}")

    return {'statusCode': 200, 'body': 'Alerts processed'}