provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "sa-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "VPC2"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "privatesubnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "privatesubnet"
  }

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "publicsubnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"

  tags {
    Name = "publicsubnet"
  }

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "publicsubnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"

  tags {
    Name = "publicsubnet2"
  }

  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "Internet Gateway terraform generated"
  }
}

resource "aws_network_acl" "all" {
  vpc_id = "${aws_vpc.main.id}"

  egress {
    protocol   = "-1"
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "open acl"
  }
}

resource "aws_route_table" "publicroutetable" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "publicroutetable"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table" "privateroutetable" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "privateroutetable"
  }
  #route {
  #      cidr_block = "0.0.0.0/0"
  #      nat_gateway_id = "${aws_nat_gateway.PublicAZA.id}"
  #}
}

resource "aws_route_table_association" "publicrtassociation" {
    subnet_id      = "${aws_subnet.publicsubnet.id}"
    route_table_id = "${aws_route_table.publicroutetable.id}"
}
resource "aws_route_table_association" "publicrtassociation2" {
    subnet_id      = "${aws_subnet.publicsubnet2.id}"
    route_table_id = "${aws_route_table.publicroutetable.id}"
}

resource "aws_route_table_association" "privatertassociation" {
  subnet_id      = "${aws_subnet.privatesubnet.id}"
  route_table_id = "${aws_route_table.privateroutetable.id}"
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = ["${aws_subnet.publicsubnet.id}", "${aws_subnet.publicsubnet2.id}"]

  tags {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "dbprivatesg" {
  name        = "dbprivatesg"
  description = "Security Group for Base A"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]

  }

  tags {
    Name = "sgA"
  }
}
resource "aws_security_group" "dbpublicsg" {
  name        = "dbpublicsg"
  description = "Security Group for Base B"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sgB"
  }
}

resource "aws_db_instance" "basea" {
  allocated_storage       = 20                                        
  backup_retention_period = 7                                         
  db_subnet_group_name    = "${aws_db_subnet_group.dbsubnetgroup.id}"
  engine                  = "mysql"
  engine_version          = "5.6.39"
  identifier              = "basea"
  instance_class          = "db.t2.micro"
  name                    = "basea"
  parameter_group_name    = "default.mysql5.6"
  # port                    = 5432
  publicly_accessible     = false
  username                = "sa"
  password                = "baseApassword"

  vpc_security_group_ids  = ["${aws_security_group.dbprivatesg.id}"]
  
}

resource "aws_db_instance" "baseb" {
  allocated_storage       = 20                                       
  backup_retention_period = 7                                         
  db_subnet_group_name    = "${aws_db_subnet_group.dbsubnetgroup.id}"
  engine                  = "mysql"
  engine_version          = "5.6.39"
  identifier              = "baseb"
  instance_class          = "db.t2.micro"
  name                    = "baseb"
  parameter_group_name    = "default.mysql5.6"
  # port                    = 5432
  publicly_accessible     = true
  username                = "sa"
  password                = "baseBpassword"

  vpc_security_group_ids  = ["${aws_security_group.dbpublicsg.id}"]
  
 }

resource "aws_dynamodb_table" "basec" {
  name           = "BaseC"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "cpf"

  #range_key      = "event"

  attribute {
    name = "cpf"
    type = "S"
  }
}

provider "mysql" "providerbasea" {
  endpoint = "${aws_db_instance.basea.endpoint}"
  username = "${aws_db_instance.basea.username}"
  password = "${aws_db_instance.basea.password}"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "basea" {
  filename         = "basea.zip"
  function_name    = "BaseA"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "exports.test"
  source_code_hash = "${base64sha256(file("basea.zip"))}"
  runtime          = "python2.7"

  vpc_config {
    subnet_ids = ["${aws_subnet.publicsubnet.id}", "${aws_subnet.privatesubnet.id}"]
    security_group_ids = ["${aws_security_group.dbpublicsg.id}"]
  }

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_lambda_function" "baseb" {
  filename         = "baseb.zip"
  function_name    = "BaseB"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "exports.test"
  source_code_hash = "${base64sha256(file("baseb.zip"))}"
  runtime          = "python2.7"

 vpc_config {
    subnet_ids = ["${aws_subnet.publicsubnet.id}", "${aws_subnet.publicsubnet2.id}"]
    security_group_ids = ["${aws_security_group.dbpublicsg.id}"]
  }

  environment {
    variables = {
      foo = "bar"
    }
  }
}

