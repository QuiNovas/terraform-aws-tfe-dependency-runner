output "notification_token" {
  description = "The generated notification token for use in TFE"
  value = "${random_string.notification_token.result}
}