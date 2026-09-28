variable "name" {
    type = string
    default = "todo-app"
}

variable "aws_account_id" {
  type = string
  default = "292578125952"
}

variable "github_token" {
  type = string
  sensitive = true
}