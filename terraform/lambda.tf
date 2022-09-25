data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  
}

resource "aws_iam_role" "lambda_policy" {
  name_prefix = "htmltopdf-lambda-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_lambda_function" "fn" {
  function_name = "htmltopdf"
  role = aws_iam_role.lambda_policy.arn

  timeout = 30
  memory_size = 2048

  package_type = "Image"
  image_uri = "${aws_ecr_repository.ecr.repository_url}:latest"
}

resource "aws_lambda_permission" "allow-apigw" {
  depends_on = [null_resource.dummy_image]

  statement_id_prefix = "AllowApiGw"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fn.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.apigw.execution_arn}/*/*"
}
