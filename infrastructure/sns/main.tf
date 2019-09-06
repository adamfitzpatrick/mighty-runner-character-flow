resource "aws_sns_topic" "character_update_topic" {
    name = "${var.environment}-${var.flow}-update-topic"
}