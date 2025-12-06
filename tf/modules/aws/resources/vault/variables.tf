variable "name" {
  description = "Secrets Manager secret name"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

