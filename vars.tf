variable "region" {
    default = "us-west-2"
}

variable "flow" {
    default = "mighty-runner-character"
}

variable "environment" {
    description = "Target environment for deployment"
    default     = "dev"
}

variable "table_name" {
    description = "Name of dynamo table"
    default     = "mighty-runner-character-flow-table"
}

variable "auth_token_table_name" {
    description = "Name of table that maintains authorized user tokens"
    default     = "mighty-runner-token"
}

variable "read_capacity" {
    description = "Provisioned read capacity for dynamo table"
    default     = 5
}

variable "write_capacity" {
    description = "Provisioned write capacity for dynamo table"
    default     = 5
}