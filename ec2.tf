#key pair

resource "aws_key_pair" "my_key" {
    key_name = "react-app-key"
    public_key = file("terraform-ec2.pub")
}

#default vpc

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

#security group
resource "aws_security_group" "ec2_SG" {
    name        = "ec2-SG"
    description = "Allow TLS inbound traffic and all outbound traffic"
    vpc_id      = aws_default_vpc.default.id #interpolation

    tags = {
    Name = "ec2-SG"
    }

    #inbound rules
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH Open"
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Http Open"
    }

    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Custom Open"
    }

    #outbound rules

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All access open outbound"
    }
}

#ec2
resource "aws_instance" "my_instance" {
    # count = 2
    for_each = tomap({
        react-app-master = "t2.small"
        react-app-worker = "t2.micro"
        react-app-worker2 = "t2.medium" 
        react-app-worker3 = "t2.large" 
    })

    depends_on = [ aws_security_group.ec2_SG, aws_key_pair.my_key ]
    key_name = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.ec2_SG.name]
    instance_type = each.value
    ami = var.ec2_ami_id
    user_data = file("install-nginx.sh")
    
    root_block_device {
      volume_size = var.env == "dev" ? var.ec2_default_root_storage_size : var.ec2_root_storage_size
      volume_type = "gp2"
    }

    tags = {
        Name = each.key
    }
}


#to import instance which is  not created by terraform
# resource "aws_instance" "unknown_instance" {
#     ami = "unknown"
#     instance_type = "unknown"
# }

# #to import key_pair which is  not created by terraform
# resource "aws_key_pair" "unknown_key_pair" {
#     public_key = "unknown"
#     key_name = "unknown"
# }




