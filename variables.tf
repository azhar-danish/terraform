variable "ec2_instance_type" {
    type = string
    default = "t2.micro"
}

variable "ec2_default_root_storage_size" {
    type = number
    default = 10
} 

variable "ec2_root_storage_size" {
    type = number
    default = 20
} 

variable "ec2_ami_id" {
    type = string
    default = "ami-01a00762f46d584a1"
}

variable "env" {
    type = string
    default = "dev"
}