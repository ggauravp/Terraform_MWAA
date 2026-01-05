resource "aws_lambda_function" "this" {
  function_name = var.lambda_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  filename      = var.filename

  layers  = var.layers
  timeout = var.timeout

  depends_on = [ var.depends_on ]

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
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = data.aws_subnets.default.ids
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = data.aws_vpc.default.id

  # Allow outbound to Postgres
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # restrict to specific CIDR blocks
  }

}
