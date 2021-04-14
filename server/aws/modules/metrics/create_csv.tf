
resource "aws_lambda_function" "unmasked_metrics" {
  function_name = "unmasked_metrics"

  image_uri = var.create_csv_image

  runtime = var.lambda_function_runtime
  role    = aws_iam_role.backoff.arn

  # vpc_config {
  #   security_group_ids = [aws_security_group.backoff_retry_sg.id]
  #   subnet_ids         = var.subnet_ids
  # }

  environment {
    variables = {
      MASK_DATA = true
    }
  }
}
resource "aws_lambda_function" "masked_metrics" {
  function_name = "masked_metrics"

  image_uri = var.create_csv_image

  runtime = var.lambda_function_runtime
  role    = aws_iam_role.backoff.arn

  # vpc_config {
  #   security_group_ids = [aws_security_group.backoff_retry_sg.id]
  #   subnet_ids         = var.subnet_ids
  # }

  environment {
    variables = {
      MASK_DATA = true
    }
  }
}

# TODO: CREATE SG for lambdas


resource "aws_cloudwatch_log_group" "masked_metrics" {
  name              = "/aws/lambda/${aws_lambda_function.masked_metrics.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "unmasked_metrics" {
  name              = "/aws/lambda/${aws_lambda_function.unmasked_metrics.function_name}"
  retention_in_days = 14
}