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
  version           = "0.2.0"
}

resource "aws_api_gateway_rest_api" "tfe_dependency_runner" {
  body        = "${data.template_file.swagger.rendered}"
  description = "Webhooks gateway for ${var.name_prefix}tfe-dependency-runner"
  name        = "${var.name_prefix}tfe-dependency-runner"
}

resource "aws_api_gateway_deployment" "tfe_dependency_runner" {
  description       = "${var.name_prefix}tfe-dependency-runner"
  rest_api_id       = "${aws_api_gateway_rest_api.tfe_dependency_runner.id}"
  stage_name        = "webhook"
}

resource "aws_lambda_permission" "tfe_dependency_runner" {
  action        = "lambda:InvokeFunction"
  function_name = "${module.tfe_dependency_runner.name}"
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowExecutionFromAPIGateway"
  source_arn    = "${aws_api_gateway_deployment.tfe_dependency_runner.execution_arn}/*/*/*"
}

resource "aws_iam_role" "tfe_dependency_runner_invocation" {
  assume_role_policy  = "${data.aws_iam_policy_document.apigateway_assume_role.json}"
  name                = "${var.name_prefix}tfe-dependency-runner-invocation"
}

resource "aws_iam_role_policy_attachment" "tfe_dependency_runner_invocation" {
  policy_arn  = "${module.tfe_dependency_runner.invoke_policy_arn}"
  role        = "${aws_iam_role.tfe_dependency_runner_invocation.name}"
}
