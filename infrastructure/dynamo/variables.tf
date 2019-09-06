variable "environment" {
    description = "Target environment for deployment"
}

variable "table_name" {
    description = "Name of dynamo table"
}

variable "hash_key" {
    description = "Hash or primary key for table"
}

variable "range_key" {
    description = "Range or sort key for table"
    default     = ""
}

variable "read_capacity" {
    description = "Provisioned read capacity for dynamo table"
}

variable "write_capacity" {
    description = "Provisioned write capacity for dynamo table"
}