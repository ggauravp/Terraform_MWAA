provider "aws" {
  region = "us-east-1"
}

# calling ec2 module to create ec2 instance
module "ec2_instance" {
    source = "./modules/ec2" # path to ec2 module
  # passing variables to ec2 module (change as needed)
    ami_id = "ami-0ecb62995f68bb549" 
    instance_type = "t3.micro"
    key_name = "my-key-pair"
    environment = "dev"
    allowed_cidr_blocks = ["0.0.0.0/0"]
}    

# calling s3 module to create s3 bucket putting dag files
module "s3_dag"{
  source = "./modules/s3"
  bucket_name = "gaurav-mwaa-bucket-123456"
  environment = "dev"
}
# calling s3 module to create s3 bucket for data storage
module "s3_data"{
  source = "./modules/s3"
  bucket_name = "gaurav-data-bucket-123456"
  environment = "dev"
}

# IAM Roles for Lambda and MWAA (calling same module(iam) twice with different parameters to create two roles)
module "iam_roles_lambda" {
  source = "./modules/iam"

  role_name = "lambda-execution-role"
  service_principal = "lambda.amazonaws.com" # Service principal for Lambda
}

module "iam_roles_mwaa" {
  source = "./modules/iam"

  role_name = "mwaa-execution-role"
  service_principal = "airflow-env.amazonaws.com" # Service principal for MWAA
}

# policy attachments to respective roles
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = module.iam_roles_lambda.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # attach logging policy to lambda role
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = module.iam_roles_lambda.role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # attach S3 full access policy to lambda role
  
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = module.iam_roles_lambda.role_name 
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" # attach VPC access policy to lambda role
}

# Policy document: allow Lambda to invoke MWAA
data "aws_iam_policy_document" "lambda_invoke_mwaa" {
  statement {
    effect = "Allow"

    actions = [
      "mwaa:CreateWebLoginToken" # Action needed to interact with MWAA
    ]

    resources = ["*"] # MWAA requires wildcard
  }
}
resource "aws_iam_policy" "lambda_mwaa" {
  name   = "lambda-mwaa-access"
  policy = data.aws_iam_policy_document.lambda_invoke_mwaa.json # create iam policy from the above document
}
resource "aws_iam_role_policy_attachment" "lambda_mwaa_attach" {
  role       = module.iam_roles_lambda.role_name
  policy_arn = aws_iam_policy.lambda_mwaa.arn
}

# Policy document: allow MWAA to invoke Lambda-2
data "aws_iam_policy_document" "mwaa_invoke_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      module.second_lambda.lambda_arn  # ARN of the second Lambda function to be invoked by MWAA
    ]
  }
}
# create iam policy from the above document
resource "aws_iam_policy" "mwaa_invoke_lambda" {
  name   = "mwaa-invoke-lambda"
  policy = data.aws_iam_policy_document.mwaa_invoke_lambda.json
}
# Attach Lambda invoke policy to MWAA role
resource "aws_iam_role_policy_attachment" "attach_mwaa_invoke_lambda" {
  role       = module.iam_roles_mwaa.role_name
  policy_arn = aws_iam_policy.mwaa_invoke_lambda.arn
}
# Custom MWAA policy to allow access to CloudWatch Logs and S3
resource "aws_iam_role_policy" "mwaa_policy" {
  name = "mwaa-custom-execution-policy"
  role =  module.iam_roles_mwaa.role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "airflow:PublishMetrics",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*" # Narrow this down to your specific buckets for better security
      }
    ]
  })
}
# Packaging Lambda function code
data "archive_file" "first_lambda_function" {
  type        = "zip"
  source_file  = "${path.module}/modules/lambda/first_lambda.py"
  output_path = "${path.module}/first_lambda_function.zip"
}
data "archive_file" "second_lambda_function"{
  type       = "zip"
  source_file  = "${path.module}/modules/lambda/second_lambda.py"
  output_path = "${path.module}/second_lambda_function.zip"
}

# creation of lambda functions by calling same lambda module twice with different parameters
module "first_lambda"{
    source = "./modules/lambda"

    lambda_name = "first_lambda_function"
    role_arn = module.iam_roles_lambda.role_arn  # use the role in this lambda function (role is created in iam module so calling that module's output)
    filename = data.archive_file.first_lambda_function.output_path
    handler = "first_lambda.lambda_handler"
    subnet_ids         = data.aws_subnets.default.ids

}
module "second_lambda"{
    source = "./modules/lambda"

    lambda_name = "second_lambda_function"
    role_arn = module.iam_roles_lambda.role_arn  # same for this lambda function as above (we can create separate roles too if needed)
    filename = data.archive_file.second_lambda_function.output_path
    handler = "second_lambda.lambda_handler"
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id] # attach security group to allow access to Postgres EC2


    layers = [module.layer.layer_arn] # attaching lambda layer created below

    db_host = module.ec2_instance.postgres_ec2_public_ip  # passing ec2 instance public ip as db_host
}

# Security group for Lambda to access Postgres EC2 instance
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda function_to_access_Postgres_EC2"
  vpc_id      = data.aws_vpc.default.id

  # Allow outbound to Postgres
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # restrict to specific CIDR blocks
  }

}

# Create Lambda layer for dependencies like psycopg2
data "archive_file" "init" {
  type        = "zip"
  source_dir  = "${path.module}/modules/layer/python"
  output_path = "${path.module}/layer.zip"
}

# creation of lambda layer by calling layer module needed to dependencies like psycopg2
module "layer"{
  source = "./modules/layer"

  filename   = data.archive_file.init.output_path
  layer_name = "my_lambda_layer"
  compatible_runtimes      = ["python3.11"]
  compatible_architectures = ["x86_64"]
}


# calling mwaa module to create mwaa environment
module "mwaa" {
  source = "./modules/mwaa"

  name               = "mwaa-dev"
  airflow_version    = "2.7.2"
  environment_class  = "mw1.small"

  execution_role_arn = module.iam_roles_mwaa.role_arn
  source_bucket_arn  = module.s3_dag.my_bucket_arn  # S3 bucket that is used to store DAG files for MWAA
  dag_s3_path        = "dags"

  subnet_ids = slice(data.aws_subnets.default.ids, 0, 2) # Use first two subnets from default VPC
  vpc_id     = data.aws_vpc.default.id

  min_workers = 1
  max_workers = 5
}


# upload DAG file to S3 bucket
resource "aws_s3_object" "dag_file" {
  depends_on = [ module.s3_dag ]
  bucket = module.s3_dag.bucket_name
  key    = "dags/s3_to_processing_dag.py" # path in S3 bucket
  source = "${path.module}/airflow/dags/s3_to_processing_dag.py" # local path to DAG file
  etag   = filemd5("${path.module}/airflow/dags/s3_to_processing_dag.py")
}


