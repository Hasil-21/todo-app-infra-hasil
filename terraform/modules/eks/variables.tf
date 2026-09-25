variable "name" {
    type = string
    default = "todo-app"
}

variable "vpc_id" {
    type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

