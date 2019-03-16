data "template_file" "swagger" {
  template = "${file("${path.module}/swagger.json")}"
  vars {
    tfe_dependency_runner_credentials = "${aws_iam_role.tfe_dependency_runner_invocation.arn}"
    tfe_dependency_runner_uri         = "${module.tfe_dependency_runner.invoke_arn}"
  }
}

data "aws_iam_policy_document" "tfe_dependency_runner" {
  statement {
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:PutItem",
      "dynamodb:Scan"
    ]
    resources = [
      "${module.dependency_table.arn}"
    ]
    sid       = "AllowAccess"
  }
}

data "aws_iam_policy_document" "apigateway_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "apigateway.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

