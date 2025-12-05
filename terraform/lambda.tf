data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "sentinel" {
  function_name = "iam-sentinel-detector"
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      SLACK_WEBHOOK = var.slack_webhook
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}