data "aws_caller_identity" "current" {}

locals {
  attributes = [
    {
      name = "${var.range_key}"
      type = "S"
    }, {
      name = "${var.hash_key}"
      type = "S"
    }
  ]

  from_index = "${length(var.range_key) > 0 ? 0 : 1}"
  attributes_final = "${slice(local.attributes, local.from_index, length(local.attributes))}"
}

resource "aws_dynamodb_table" "dynamo_table" {
  name           = "${var.environment}-${var.table_name}"
  billing_mode   = "PROVISIONED"
  read_capacity  = "${var.read_capacity}"
  write_capacity = "${var.write_capacity}"
  hash_key       = "${var.hash_key}"
  range_key      = "${var.range_key}"
  attribute      = "${local.attributes_final}"

  server_side_encryption {
    enabled = true
  }

  lifecycle {
      prevent_destroy = true
      ignore_changes = [ "read_capacity", "write_capacity" ]
  }
}

resource "aws_appautoscaling_target" "table_read_target" {
  max_capacity       = "${var.read_capacity * 10}"
  min_capacity       = "${var.read_capacity}"
  resource_id        = "table/${aws_dynamodb_table.dynamo_table.name}"
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/dynamodb.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_DynamoDBTable"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  depends_on         = ["aws_dynamodb_table.dynamo_table"]
}

resource "aws_appautoscaling_target" "table_write_target" {
  max_capacity       = "${var.write_capacity * 10}"
  min_capacity       = "${var.write_capacity}"
  resource_id        = "table/${aws_dynamodb_table.dynamo_table.name}"
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/dynamodb.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_DynamoDBTable"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  depends_on         = ["aws_dynamodb_table.dynamo_table"]
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.table_read_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.table_read_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.table_read_target.service_namespace}"
  depends_on         = ["aws_dynamodb_table.dynamo_table"]

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 60
  }
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.table_write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.table_write_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.table_write_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.table_write_target.service_namespace}"
  depends_on         = ["aws_dynamodb_table.dynamo_table"]

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 60
  }
}