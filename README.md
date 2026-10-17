# terraform
Installing

sudo apt-get update
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg


echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list


sudo apt update && sudo apt install terraform


On local macOS machine


brew tap hashicorp/tap

brew install hashicorp/tap/terraform

Eg: vi myfile.tf
resource local_file my_file { 
	filename= "automate.txt"
	content= "hello world"
}

terraform init
terraform validate
Terraform plan
terraform apply
terraform destroy


> ls
automate.txt  main.tf  terraform.tfstate








> vi terraform.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.69.0"
    }


  }
}

> terraform init



Aws provider will be downloaded

We can also set the region using provider

> vi provider.tf

Provider “aws” {
	region=”us-east-1”
}

> terraform init

Now create s3 buket 
First need to download aws cli and then configure

> ls
 myfile.tf  provider.tf  s3-bucket.tf  terraform.tfstate  terraform.tfstate.backup  terrafrom.tf

> cat s3-bucket.tf
resource aws_s3_bucket my-bucket {
	bucket = "terraform-bucket-azhar"
}


> t init
>t validate
>t plan
>t apply


From Local MacBook

resource aws_s3_bucket my-bucket {
	bucket = "terraform-bucket-azhar-local"
	region = "us-east-1"
}


EC2 instance

> mkdir ec2
> ls
ec2
> cd ec2
ec2> ssh-keygen
terraform-ec2  terraform-ec2.pub

ec2 > touch ec2.tf


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
       description = "HTTP Open"
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
   key_name = aws_key_pair.my_key.key_name
   security_groups = [aws_security_group.ec2_SG.name]
   instance_type = var.ec2_instance_type
   ami = var.ec2_ami_id
  
   root_block_device {
     volume_size = var.ec2_root_storage_size
     volume_type = "gp2"
   }


   tags = {
       Name = "react-app-instance"
   }
}









 ec2 > touch variables.tf



variable "ec2_instance_type" {
   type = string
   default = "t2.micro"
}


variable "ec2_root_storage_size" {
   type = number
   default = 20
}


variable "ec2_ami_id" {
   type = string
   default = "ami-01a00762f46d584a1"
}







ec2 > touch outputs.tf


output "ec2_private_ip" {
   value = aws_instance.my_instance.private_ip
}


output "ec2_public_ip" {
   value = aws_instance.my_instance.public_ip
}


output "ec2_public_dns" {
   value = aws_instance.my_instance.public_dns
}






ec2 > ls
ec2.tf				terraform-ec2			terraform.tfstate		variables.tf
outputs.tf			terraform-ec2.pub		terraform.tfstate.backup


ec2 > terraform init
	Terraform validate
	Terraform plan
	Terraform apply
	
Outputs:
ec2_public_dns = "ec2-15-252-185-221.ap-south-1.compute.amazonaws.com"
ec2_public_ip = "15.252.185.221"

ec2 > ssh -i terraform-ec2 ubuntu@ec2-15-252-185-221.ap-south-1.compute.amazonaws.com



Count : When creating multiple instance




resource "aws_instance" "my_instance" {
   Count = 2
   
   key_name = aws_key_pair.my_key.key_name
   security_groups = [aws_security_group.ec2_SG.name]
   instance_type = var.ec2_instance_type
   ami = var.ec2_ami_id
   user_data = file("install-nginx.sh")
  
   root_block_device {
     volume_size = var.ec2_root_storage_size
     volume_type = "gp2"
   }


   tags = {
       Name = each.key
   }
}











For_each in main.tf while creating resource




resource "aws_instance" "my_instance" {
   # count = 2
   for_each = tomap({
       react-app-master = "t2.small"
       react-app-worker = "t2.micro"
   })
   key_name = aws_key_pair.my_key.key_name
   security_groups = [aws_security_group.ec2_SG.name]
   instance_type = each.value
   ami = var.ec2_ami_id
   user_data = file("install-nginx.sh")
  
   root_block_device {
     volume_size = var.ec2_root_storage_size
     volume_type = "gp2"
   }


   tags = {
       Name = each.key
   }
}




for_each used in output




output "ec2_private_ip" {
   value = {
       for k, v in aws_instance.my_instance : k => v.private_ip
   }
}
output "ec2_public_ip" {
   value = {
       for k, v in aws_instance.my_instance : k => v.public_ip
   }
}


output "ec2_public_dns" {
   value = {
       for k, v in aws_instance.my_instance : k => v.public_dns
   }
}








Depends_on: 

depends_on = [ aws_security_group.ec2_SG, aws_key_pair.my_key ]



Conditional_statement : 




resource "aws_instance" "my_instance" {
   # count = 2
   for_each = tomap({
       react-app-master = "t2.small"
       react-app-worker = "t2.micro"
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


variable "ec2_default_root_storage_size" {
   type = number
   default = 10
}


variable "ec2_root_storage_size" {
   type = number
   default = 20
}


Terraform State

> terraform refresh
> terraform state list
aws_default_vpc.default
aws_instance.my_instance["react-app-master"]
aws_instance.my_instance["react-app-worker"]
aws_key_pair.my_key
aws_security_group.ec2_SG
azhardanish@Mac ec2 % t s


> terraform state show 

>terraform  state show aws_key_pair.my_key    
 
# aws_key_pair.my_key:
resource "aws_key_pair" "my_key" {
    arn             = "arn:aws:ec2:ap-south-1:024901689513:key-pair/react-app-key"
    fingerprint     = "4gf6sL/kjp2ZlR9A68cg2iCF5FZUlKsAl01V+8bxr4I="
    id              = "react-app-key"
    key_name        = "react-app-key"
    key_name_prefix = null
    key_pair_id     = "key-062660eccd98421f8"
    key_type        = "ed25519"
    public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILELfi5DxZR/yodbNVXeeurQlGCCRhX8cwy8fpD5P4yd azhardanish@Mac"
    region          = "ap-south-1"
    tags            = {}
    tags_all        = {}
}

> terraform state rm aws_key_pair.my_key
Removed aws_key_pair.my_key
Successfully removed 1 resource instance(s).




LockState






#to import instance which is  not created by terraform
resource "aws_instance" "unknow_instance" {
   ami = "unknown"
   instance_type = "unknown"
}

> terraform import aws_instance.unknown_instance i-017105c04342f3b32

aws_instance.unknown_instance: Importing from ID "i-017105c04342f3b32"...
aws_instance.unknown_instance: Import prepared!
  Prepared aws_instance for import
aws_instance.unknown_instance: Refreshing state... [id=i-017105c04342f3b32]
Import successful!
The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.


> terraform state list
aws_default_vpc.default
aws_instance.my_instance["react-app-master"]
aws_instance.my_instance["react-app-worker"]
aws_instance.unknown_instance
aws_security_group.ec2_SG

To get the detail of unknow resource
> terraform state show aws_instance.unknown_instance



#to import key_pair which is  not created by terraform



 resource "aws_key_pair" "unknown_key_pair" {
   public_key = "unknown"
   key_name = "unknown"
 }




> terraform import aws_key_pair.unknown_key_pair <key-pair-name>


> terraform import aws_key_pair.unknown_key_pair node-instance
> terraform state list
aws_default_vpc.default
aws_instance.my_instance["react-app-master"]
aws_instance.my_instance["react-app-worker"]
aws_instance.unknown_instance
aws_key_pair.unknown_key_pair
aws_security_group.ec2_SG



State Locking

Create s3 bucket with name : terraform-remote-infra
Create dynamo db table : state_table


In the terraform.tf file



terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "6.69.1"
   }
 }


 backend "s3" {
   bucket = "terraform-remote-infra-azhar"
   key = "terraform.tfstate"
   region = "ap-south-1"
   dynamodb_table = "state_table"
 }
}




In first terminal


> terraform init
> terrafrom plan
> terraform apply
  It ask for a value :   




At the same time an object in the bucket has been generated and a row consists of lockID has been created in the dynamodb table of state_table



{
  "LockID": {
    "S": "terraform-remote-infra-azhar/terraform.tfstate"
  },
  "Info": {
    "S": "{\"ID\":\"cfcfe80e-bb12-e45a-dd66-09dad050d999\",\"Operation\":\"OperationTypeApply\",\"Info\":\"\",\"Who\":\"azhardanish@Mac\",\"Version\":\"1.16.6\",\"Created\":\"2026-10-17T08:39:00.467104Z\",\"Path\":\"terraform-remote-infra-azhar/terraform.tfstate\"}"
  }
}




So if the other user try to apply resource ,it will throw error


In second terminal
> terraform init
> terraform plan

It throws error 
│ Warning: Deprecated Parameter
│ 
│ The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
╵
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: operation error DynamoDB: PutItem, https response error StatusCode: 400, RequestID: M5RTNB15FKKG14R6G1C7VFJ43NVV4KQNSO5AEMVJF66Q9ASUAAJG, ConditionalCheckFailedException: The conditional
│ request failed
│ Lock Info:
│   ID:        7d2e98dd-effe-3817-25ee-f77f237ccbab
│   Path:      terraform-remote-infra-azhar/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       azhardanish@Mac
│   Version:   1.16.6
│   Created:   2026-10-17 07:44:33.099065 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.




As soon as the first developer complete his task of apply the LockID has been removed ,and now the second developer can perform his tasks


Environment (Workspaces)

> terraform workspace list
* default

> terraform workspace new dev

Created and switched to workspace "dev"!
You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.

> terraform state list
Nothing to show

> terraform workspace list
  default
* dev

> terraform workspace select default
Switched to workspace "default".

> terraform state list              
aws_default_vpc.default
aws_instance.my_instance["react-app-master"]
aws_instance.my_instance["react-app-worker"]
aws_instance.my_instance["react-app-worker2"]
aws_instance.my_instance["react-app-worker3"]
aws_key_pair.my_key
aws_security_group.ec2_SG







IAM user and grant him s3 full accss


