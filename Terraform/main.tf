terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"  # ¡Tu región!
}

# Variables (ajusta los valores según tu configuración)
variable "s3_bucket_name" {
  description = "Nombre del bucket S3 donde está el código Lambda"
  default     = "matias-cost-assets"  # ¡Reemplaza con tu bucket real!
}

variable "sns_topic_name" {
  description = "Nombre del tema SNS para alertas"
  default     = "CostsAlertSNS"
}

variable "lambda_function_name" {
  description = "Nombre de la función Lambda"
  default     = "ProcesadorAlertasCosto-TF"
}

variable "lambda_role_name" {
  description = "Nombre del Rol IAM para la Lambda"
  default     = "LambdaProcesaAlertasRole-TF"
}

# 1. Crear tema SNS
resource "aws_sns_topic" "cost_alerts_topic" {
  name = var.sns_topic_name
}

# 2. Rol IAM para Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 3. Política de permisos para Lambda (logs)
resource "aws_iam_role_policy_attachment" "lambda_logs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4. Función Lambda (desde S3)
resource "aws_lambda_function" "cost_alert_processor" {
  function_name = var.lambda_function_name
  s3_bucket     = var.s3_bucket_name
  s3_key        = "Lambda/lambda_function.zip"  # ¡Verifica la ruta en S3!
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
}

# 5. Permiso para que SNS invoque Lambda
resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  statement_id  = "AllowSNSToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_alert_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cost_alerts_topic.arn
}

# 6. Suscripción de Lambda al tema SNS
resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  topic_arn = aws_sns_topic.cost_alerts_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cost_alert_processor.arn
}

# Outputs
output "lambda_arn" {
  value = aws_lambda_function.cost_alert_processor.arn
}
