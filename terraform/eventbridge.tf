resource "aws_cloudwatch_event_rule" "iam_changes" {
  name        = "iam-sentinel-iam-events"
  description = "Trigger Lambda on ANY IAM API event recorded by CloudTrail"

  event_pattern = jsonencode({
    "source": ["aws.iam"],
    "detail-type": ["AWS API Call via CloudTrail"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.iam_changes.name
  target_id = "iam-sentinel-lambda-target"
  arn       = aws_lambda_function.sentinel.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sentinel.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam_changes.arn
}