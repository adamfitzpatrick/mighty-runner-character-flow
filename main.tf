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

module authorizer-lambda {
    source = "../mighty-runner-authorizer/infrastructure"

    function_name    = "${var.environment}-${var.flow}-authorizer"
    dynamo_table_arn        = "${module.token_table.dynamo_table_arn}"
    table_name              = "${module.token_table.dynamo_table_name}"
    primary_key_column_name = "${local.tokenTableHashKey}"
}

module update_topic {
    source = "./infrastructure/sns"

    flow        = "${var.flow}"
    environment = "${var.environment}"
}

module enqueue-lambda {
    source = "../mighty-runner-enqueue-lambda/infrastructure"

    function_name    = "${var.environment}-${var.flow}-enqueue-lambda"
    topic_arn        = "${module.update_topic.topic_arn}"
    auth_token_field = "${local.userId}"
    object_id_field  = "${local.objectId}"
}

module persist-lambda {
    source = "../mighty-runner-persist-lambda/infrastructure"

    function_name    = "${var.environment}-${var.flow}-persist-lambda"
    dynamo_table_arn        = "${module.character_table.dynamo_table_arn}"
    topic_arn               = "${module.update_topic.topic_arn}"
    table_name              = "${var.environment}-${var.table_name}"
    primary_key_column_name = "${local.userId}"
    sort_key_column_name    = "${local.objectId}"
}

module get-lambda {
    source = "../mighty-runner-get-lambda/infrastructure"

    function_name    = "${var.environment}-${var.flow}-get-lambda"
    dynamo_table_arn        = "${module.character_table.dynamo_table_arn}"
    table_name              = "${var.environment}-${var.table_name}"
    primary_key_column_name = "${local.userId}"
    sort_key_column_name    = "${local.objectId}"
}

module api_gateway {
    source = "./infrastructure/api-gateway"

    authorizer_invoke_arn     = "${module.authorizer-lambda.invoke_arn}"
    get-lambda_invoke_arn     = "${module.get-lambda.invoke_arn}"
    enqueue-lambda_invoke_arn = "${module.enqueue-lambda.invoke_arn}"

}