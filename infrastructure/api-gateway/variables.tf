variable "account_id" {
    description = "Account into which this API is to be deployed"
}

variable "region" {
    description = "Region for use with AWS"
    default     = "us-west-2"
}

variable "flow" {
    description = "API flow name used to populate resource names"
    default     = "mighty-runner-character"
}

variable "environment" {
    description = "Environment to which the API is deployed"
    default     = "dev"
}

variable "authorizer_function_name" {
    description = "Lambda function name to be invoked as an authorizer"
}

variable "get-lambda_invoke_arn" {
    description = "ARN for invoking the get-lambda"
}

variable "enqueue-lambda_invoke_arn" {
    description = "ARN for invoking the enqueue-lambda"
}

variable "cloudwatch_log_retention_in_days" {
    description = "Days to retain log records"
    default     = 365
}