data "archive_file" "lamba_zip" {
    type        = "zip"
    source_file = "lambda_function.py"
    output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "slack_notifier" {
    filename = "lambda_function.zip"
    function_name    = "${var.project_name}-slack-notifier"
    role             = aws_iam_role.lambda_role.arn
    handler          = "lambda_function.lambda_handler"
    runtime          = var.python_version
    source_code_hash = data.archive_file.lamba_zip.output_base64sha256

    environment {
      variables = {
        SLACK_WEBHOOK_URL = var.SLACK_WEBHOOK_URL
      }
    }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
    statement_id  = "AllowExecutionFromCloudWatch"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.slack_notifier.function_name
    principal     = "logs.amazonaws.com"
    source_arn    = "${aws_cloudwatch_log_group.api_logs.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "slack_filter" {
    name            = "slack-error-filter"
    log_group_name  = aws_cloudwatch_log_group.api_logs.name
    filter_pattern  = "?ERROR ?Error ?error"
    destination_arn = aws_lambda_function.slack_notifier.arn
}