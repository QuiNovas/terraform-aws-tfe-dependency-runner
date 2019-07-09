output "invoke_url" {
  description = "The URL to invoke the TFE Dependency runner api"
  value       = "${aws_api_gateway_deployment.tfe_dependency_runner.invoke_url}/tfe-dependency-runner"
}

output "notification_token" {
  description = "The generated notification token for use in TFE"
  value       = random_string.notification_token.result
}

