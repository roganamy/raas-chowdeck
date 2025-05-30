resource "honeycombio_slack_recipient" "alerts" {
  count   = var.create_slack_recipient ? 1 : 0
  channel = var.slack_recipient_channel
}
