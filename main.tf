module "dependency_table" {
  attributes    = [
    {
      name = "organization_name"
      type = "S"
    },
    {
      name = "workspace_name"
      type = "S"
    }
  ]
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "organization_name"
  name          = "${var.name_prefix}tfe-dependency-runner"
  range_key     = "workspace_name"
  source        = "QuiNovas/dynamodb-table/aws"
  version       = "2.0.1"
}

resource "aws_iam_policy" "tfe_dependency_runner" {
  name    = "${var.name_prefix}LambdaLambdaLambdaTfeDependencyRunner"
  policy  = "${data.aws_iam_policy_document.tfe_dependency_runner.json}"
}

resource "random_string" "notification_token" {
  length = 32
  special = false
}

module "tfe_dependency_runner" {
  dead_letter_arn   = "${var.dead_letter_arn}"
  environment_variables {
    API_TOKEN = "${var.api_token}"
    NOTIFICATION_TOKEN = "${random_string.notification_token.result}"
    WORKSPACE_DEPENDENCIES_TABLE = "${module.dependency_table.name}"
  }
  handler           = "function.handler"
  kms_key_arn       = "${var.kms_key_arn}"
  l3_object_key     = "quinovas/tfe-dependency-runner/tfe-dependency-runner-0.0.1.zip"
  name              = "${var.name_prefix}tfe-dependency-runner"
  policy_arns       = [
    "${aws_iam_policy.tfe_dependency_runner.arn}",
  ]
  policy_arns_count = 1
  runtime           = "python3.7"
  source            = "QuiNovas/lambdalambdalambda/aws"
  timeout           = 30
  version           = "0.2.0"
}

resource "aws_api_gateway_rest_api" "tfe_dependency_runner" {
  description = "Webhooks gateway for ${var.name_prefix}tfe-dependency-runner"
  name        = "${var.name_prefix}tfe-dependency-runner"
}

resource "aws_api_gateway_resource" "tfe_dependency_runner" {
  rest_api_id = "${aws_api_gateway_rest_api.tfe_dependency_runner.id}"
  parent_id   = "${aws_api_gateway_rest_api.tfe_dependency_runner.root_resource_id}"
  path_part   = "tfe-dependency-runner"
}

resource "aws_api_gateway_method" "POST" {
  rest_api_id   = "${aws_api_gateway_rest_api.tfe_dependency_runner.id}"
  resource_id   = "${aws_api_gateway_resource.tfe_dependency_runner.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tfe_dependency_runner" {
  rest_api_id             = "${aws_api_gateway_rest_api.tfe_dependency_runner.id}"
  resource_id             = "${aws_api_gateway_resource.tfe_dependency_runner.id}"
  http_method             = "${aws_api_gateway_method.POST.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${module.tfe_dependency_runner.invoke_arn}"
}

resource "aws_api_gateway_deployment" "tfe_dependency_runner" {
  depends_on        = [
    "aws_api_gateway_integration.tfe_dependency_runner"
  ]
  description       = "${var.name_prefix}tfe-dependency-runner"
  rest_api_id       = "${aws_api_gateway_rest_api.tfe_dependency_runner.id}"
  stage_name        = "webhook"
}

resource "aws_lambda_permission" "tfe_dependency_runner" {
  action        = "lambda:InvokeFunction"
  function_name = "${module.tfe_dependency_runner.name}"
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowExecutionFromAPIGateway"
  source_arn    = "${aws_api_gateway_deployment.tfe_dependency_runner.execution_arn}/POST/tfe-dependency-runner"
}
