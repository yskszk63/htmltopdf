resource "aws_apigatewayv2_api" "apigw" {
  name = "htmltopdf"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "apigw" {
  api_id = aws_apigatewayv2_api.apigw.id
  integration_type = "AWS_PROXY"
  connection_type = "INTERNET"
  integration_method = "ANY"
  integration_uri = aws_lambda_function.fn.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "any" {
  api_id = aws_apigatewayv2_api.apigw.id
  route_key = "ANY /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.apigw.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.apigw.id
  name = "$default"
  auto_deploy = true
}
