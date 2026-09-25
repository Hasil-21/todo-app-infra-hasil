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

variable "db_name" {
    type = string
    default = "TodoAppDb"
}

variable "username" {
    type = string
    default = "TodoAppAdmin"
}

variable "db_ingress_cidr" {
    type = list(string)
}

variable "db_ingress_sg" {
    type = list(string)
}