data "aws_caller_identity" "current" {}

locals {
  userId            = "userId"
  objectId          = "id"
  tokenTableHashKey = "token"
}


module character_table {
    source = "./infrastructure/dynamo"

    environment    = "${var.environment}"
    table_name     = "${var.table_name}"
    hash_key       = "${local.userId}"
    range_key      = "${local.objectId}"
    read_capacity  = 5
    write_capacity = 5
}

module token_table {
    source = "./infrastructure/dynamo"

    environment    = "${var.environment}"
    table_name     = "${var.auth_token_table_name}"
    hash_key       = "${local.tokenTableHashKey}"
    read_capacity  = 5
    write_capacity = 5
}

module update_topic {
    source = "./infrastructure/sns"

    flow        = "${var.flow}"
    environment = "${var.environment}"
}

module enqueue-lambda {
    source = "github.com/adamfitzpatrick/mighty-runner-enqueue-lambda.git//infrastructure"

    function_name    = "${var.environment}-${var.flow}-enqueue-lambda"
    topic_arn        = "${module.update_topic.topic_arn}"
    auth_token_field = "${local.userId}"
    object_id_field  = "${local.objectId}"
}

module persist-lambda {
    source = "github.com/adamfitzpatrick/mighty-runner-persist-lambda.git//infrastructure"

    function_name    = "${var.environment}-${var.flow}-persist-lambda"
    dynamo_table_arn        = "${module.character_table.dynamo_table_arn}"
    topic_arn               = "${module.update_topic.topic_arn}"
    table_name              = "${var.environment}-${var.table_name}"
    primary_key_column_name = "${local.userId}"
    sort_key_column_name    = "${local.objectId}"
}

module get-lambda {
    source = "github.com/adamfitzpatrick/mighty-runner-get-lambda.git//infrastructure"

    function_name    = "${var.environment}-${var.flow}-get-lambda"
    dynamo_table_arn        = "${module.character_table.dynamo_table_arn}"
    table_name              = "${var.environment}-${var.table_name}"
    primary_key_column_name = "${local.userId}"
    sort_key_column_name    = "${local.objectId}"
}

module api_gateway {
    source = "./infrastructure/api-gateway"

    account_id                = "${data.aws_caller_identity.current.account_id}"
    authorizer_function_name  = "${var.environment}-mighty-runner-authorizer"
    get-lambda_invoke_arn     = "${module.get-lambda.invoke_arn}"
    enqueue-lambda_invoke_arn = "${module.enqueue-lambda.invoke_arn}"

}