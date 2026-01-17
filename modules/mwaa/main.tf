# security group for MWAA environment
resource "aws_security_group" "mwaa_sg" {
  name        = "${var.name}-sg"
  description = "Security group for MWAA"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true # This means "Allow traffic from myself"
  }
  
  # MWAA requires outbound internet/VPC access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_mwaa_environment" "this" {
  name = var.name

  airflow_version    = var.airflow_version
  environment_class  = var.environment_class
  execution_role_arn = var.execution_role_arn

  source_bucket_arn = var.source_bucket_arn
  dag_s3_path       = var.dag_s3_path

  network_configuration {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.mwaa_sg.id]
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  min_workers = var.min_workers
  max_workers = var.max_workers

  webserver_access_mode = "PUBLIC_ONLY"

  airflow_configuration_options = {
    "core.load_examples" = "false"
  }
}

