# AWSCloudSolution

## Instructions

To deploy this solution, download the project and extract it to a folder in your computer.

In terminal, go to the folder where you've extracted the project and type:

```
chmod 700 deploy.sh
./deploy.sh
```

## Description 
This solution was built for accessing data from 3 databases: Base A, Base B and Base C. 
The deployment and constrution of the required AWS architecture was made through the [Terraform](https://www.terraform.io) tool. 
The code, which Terraform uses to build the architecture, can be found inside the file:

```
terraform/terraform.tf
```

### Base A
The folder "Base A" has the client to connect to Base A database. The database is a MySQL server instance from Amazon RDS, running inside a private subnet to avoid being accessed from outside of its VPC.
The client to connect to this databases uses [SQLAlchemy](http://www.sqlalchemy.org) and CyMySQL and it can be found in:
```
BaseA/basea.py
```

### Base B
The Database B, is also a MySQL server instance, but inside a public subnet with a public IP and  a table route defined to be accessible from the outside. It has an API client in:
```
BaseB/baseb.py
```

### Base C
The database C is a DynamoDB, accessible through a REST service built with [Flask](http://flask.pocoo.org), [Boto3 SDK](https://github.com/boto/boto3) and easily depployed to AWS with [Zappa](https://github.com/Miserlou/Zappa).

