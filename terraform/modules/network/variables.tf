variable "name" {
    type = string
    default = "todo-app"
}

variable "cidr_block" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_ids" {
    type = list(string)
    default = [ "10.0.1.0/24","10.0.2.0/24" ]
}

variable "private_subnet_ids" {
    type = list(string)
    default = [ "10.0.3.0/24","10.0.4.0/24" ] 
}

variable "availability_zone" {
    type = list(string)
    default = [ "ap-south-1a","ap-south-1b" ]
}