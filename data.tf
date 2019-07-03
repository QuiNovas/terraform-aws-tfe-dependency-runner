data "template_file" "swagger" {
  template = file("${path.module}/swagger.json")
  vars = {
    tfe_dependency_runner_uri = module.tfe_dependency_runner.invoke_arn
  }
}

data "aws_iam_policy_document" "tfe_dependency_runner" {
  statement {
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
    ]
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    resources = flatten([
      module.dependency_table.arn,
    ])
    sid = "AllowAccess"
  }
}

