# terraform-aws-tfe-dependency-runner

This module creates a webhook endpoint for managing Terraform Enterprise dependency runs.

To use this with Terraform Enterprise:
1. Implement the module in an AWS account.
2. For each workspace in TFE, implement the webhook notification using the API endpoint exposed from the module and the notification token that you passed into the module.

Now all builds in each workspace will run any dependent TFE workspaces.

## Authors

Module managed by Quinovas (https://github.com/QuiNovas)
