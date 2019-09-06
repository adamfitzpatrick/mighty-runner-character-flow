output "topic_arn" {
    value = "${aws_sns_topic.character_update_topic.arn}"
}