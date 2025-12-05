import json
import boto3
import os
import urllib.request

sns = boto3.client("sns")

SLACK_WEBHOOK = os.getenv("SLACK_WEBHOOK")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

HIGH_RISK_EVENTS = [
    "CreateUser",
    "DeleteUser",
    "CreateAccessKey",
    "PutUserPolicy",
    "AttachUserPolicy",
    "AttachGroupPolicy",
    "AttachRolePolicy",
    "UpdateAssumeRolePolicy",
    "AddUserToGroup",
    "RemoveUserFromGroup",
]


def send_slack_message(text: str) -> None:
    """Send a simple text message to Slack via incoming webhook."""
    if not SLACK_WEBHOOK:
        print("SLACK_WEBHOOK not set, skipping Slack.")
        return

    payload = {"text": text}
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        SLACK_WEBHOOK,
        data=data,
        headers={"Content-Type": "application/json"}
    )

    try:
        with urllib.request.urlopen(req) as resp:
            print("Slack response status:", resp.status)
    except Exception as e:
        print("Slack delivery failed:", str(e))


def lambda_handler(event, context):
    # Basic debug
    print("Received event:", json.dumps(event))

    detail = event.get("detail", {})
    event_name = detail.get("eventName")
    user = detail.get("userIdentity", {}).get("arn", "Unknown")
    source_ip = detail.get("sourceIPAddress", "Unknown")
    request_params = detail.get("requestParameters", {})

    if event_name in HIGH_RISK_EVENTS:
        alert = {
            "severity": "HIGH",
            "event": event_name,
            "user": user,
            "source_ip": source_ip,
            "parameters": request_params,
        }

        slack_text = (
            "🚨 *IAM Sentinel Alert — HIGH RISK*\n"
            f"*Event:* `{event_name}`\n"
            f"*User:* `{user}`\n"
            f"*Source IP:* `{source_ip}`\n\n"
            "```json\n"
            f"{json.dumps(request_params, indent=2)}\n"
            "```"
        )

        # Slack
        send_slack_message(slack_text)

        # SNS
        if SNS_TOPIC_ARN:
            try:
                sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Message=json.dumps(alert),
                    Subject=f"IAM Sentinel Alert - {event_name}",
                )
                print("SNS alert sent.")
            except Exception as e:
                print("SNS publish failed:", str(e))
        else:
            print("SNS_TOPIC_ARN not set, skipping SNS.")
    else:
        print(f"Ignored event: {event_name}")

    return {"status": "ok"}