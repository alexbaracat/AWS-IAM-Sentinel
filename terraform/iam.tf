resource "aws_iam_role" "lambda_exec" {
  name = "iam-sentinel-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "iam-sentinel-lambda-logs"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "sns_publish" {
  name       = "iam-sentinel-sns-publish"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}