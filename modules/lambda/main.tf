resource "aws_lambda_function" "this" {
  function_name = var.lambda_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  filename      = var.filename

  layers  = var.layers
  timeout = var.timeout


   environment {
    variables = {
      DB_HOST     = var.db_host
      DB_NAME     = var.db_name
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
      DB_PORT     = "5432"
    }
  }

  source_code_hash = filebase64sha256(var.filename)

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }
}

