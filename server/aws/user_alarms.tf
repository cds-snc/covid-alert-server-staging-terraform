module "ops_alarms" {
  source                = "github.com/cds-snc/terraform-modules//user_login_alarm@v0.01"
  account_names         = ["ops1", "ops2"]
  alarm_action_failures = [aws_sns_topic.alert_warning.arn]
  alarm_action_success  = [aws_sns_topic.alert_critical.arn]
  log_group_name        = "CloudTrail/Landing-Zone-Logs"
  num_attempts          = 3
}