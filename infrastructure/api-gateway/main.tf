data "template_file" "oas" {
  template = "${file("${path.module}/mighty-runner-character-flow.template.yaml")}"

  vars = {
    environment                = "${var.environment}"
    get-lambda_invoke_arn      = "${var.get-lambda_invoke_arn}"
    enqueue-lambda_invoke_arn  = "${var.enqueue-lambda_invoke_arn}"
    authorizer_invoke_arn      = "${var.authorizer_invoke_arn}"
    authorizer_invoke_role_arn = "${aws_iam_role.authorizer-invoke.arn}"
  }
}

data "template_file" "api_assume_role_policy" {
  template = "${file("${path.root}/infrastructure/policies/api-gateway-assume-role.template.json")}"
}

data "template_file" "api_cloudwatch_policy" {
  template = "${file("${path.root}/infrastructure/policies/api-gateway-cloudwatch.template.json")}"
}

data "template_file" "authorizer_invoke_policy" {
  template = "${file("${path.root}/infrastructure/policies/authorizer-invoke-policy.template.json")}"
}

resource "aws_lambda_permission" "allow_apigateway_authorizer" {
  statement_id  = "AllowAthorizerExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-${var.flow}-authorizer"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "allow_apigateway_get-lambda" {
  statement_id  = "AllowGetLambdaExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-${var.flow}-get-lambda"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "allow_apigateway_enqueue-lambda" {
  statement_id  = "AllowEnqueueLambdaExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-${var.flow}-enqueue-lambda"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*/*"
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.environment}-${var.flow}-api"
  description = "API flow for providing and storing Shadowrun characters"
  body        = "${data.template_file.oas.rendered}"
}

resource "aws_api_gateway_deployment" "api_gateway" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway.id}"
  stage_name  = "${var.environment}"

  variables {
    deployed_at = "${timestamp()}"
  }
}

resource "aws_iam_role" "api_gateway" {
  name               = "api-gateway-account-role"
  assume_role_policy = "${data.template_file.api_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  role   = "${aws_iam_role.api_gateway.id}"
  policy = "${data.template_file.api_cloudwatch_policy.rendered}"
}

resource "aws_iam_role" "authorizer-invoke" {
  name = "${var.environment}-${var.flow}-authorizer-invoke"
  assume_role_policy = "${data.template_file.api_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "authorizer-invoke-policy" {
  role   = "${aws_iam_role.authorizer-invoke.id}"
  policy = "${data.template_file.authorizer_invoke_policy.rendered}"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = "${aws_iam_role.api_gateway.arn}"
}

resource "aws_cloudwatch_log_group" "api_gateway_cloudwatch" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.api_gateway.id}"
  retention_in_days = "${var.cloudwatch_log_retention_in_days}"
}