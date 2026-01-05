resource "aws_lambda_layer_version" "this"{
    filename = var.filename
    layer_name = var.layer_name
    compatible_runtimes = var.compatible_runtimes
    compatible_architectures = var.compatible_architectures
}

