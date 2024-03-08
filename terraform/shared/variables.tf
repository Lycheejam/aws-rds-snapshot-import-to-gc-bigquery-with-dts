variable "aws_access_key_id" {
  description = "The AWS access key ID"
  type        = string
}

variable "aws_secret_access_key" {
  description = "The AWS secret access key"
  type        = string
}

variable "gc_project_id" {
  description = "The Google Cloud project ID"
  type        = string
  default     = "sample-project"
}

variable "db_instance_identifier" {
  description = "The RDS instance identifier"
  type        = string
}

variable "schema_name" {
  description = "The name of the schema to import"
  type        = string
}

variable "short_env" {
  description = "The short name of the environment"
  type        = string
  default     = "dev"
}

variable "is_dts_scheduled_queries_disabled" {
  description = "Whether to disable the scheduled queries for Data Transfer Service"
  type        = bool
  default     = true # NOTE: IsDisabled? なのでfalseでスケジュール実行が有効、trueで無効になる。
}

variable "tables" {
  description = "The list of tables to import"
  type        = list(string)
  default = [
    "table1",
    "table2",
    "table3",
    "table4",
    "table5",
  ]
}
