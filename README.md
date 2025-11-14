# IaC - General Documenation

Infrastructure-as-code for static site.

---

---

## Setup - Authenticating to AWS:

### Steps:

#### 1. Installation of AWS CLI

Self explanatory

---

#### 2. AWS Authentication

```
$ aws configure
```

---

#### 3. User Group Creation

This command will prompt for two keys, this will need to be a user with role(s)/permissions to do what your code is designed to do. Most of this is done on the AWS console. This is the order you should be going through:

Path: Console -> Search IAM -> User Groups (under IAM Dashboard) -> Create Group

These are the permissions the group should have for this kind of project:

    -- AmazonDynamoDBFullAccess

    -- AmazonRoute53FullAccess

    -- AmazonRDSFullAccess

    -- AmazonEC2FullAccess

    -- AmazonS3FullAccess

    -- AmazonIAMFullAccess

---

#### 4. User Creation

Path: Users (under IAM Dashboard) -> Create User

Then create a user and assign it the group we just made.

---

#### 5. Finish Authentication

Then, click this new user, and go to the "Security Credentials" tab, you'll have to create an access key, then you'll copy the access key and then the secret access key to be used within the AWS CLI.

---

## Setup - Terraform Commands

### `terraform init`

Downloads associated providers we defined in the Terraform Block under `.terraform` directory. Also creates `.terraform.lock.hcl` file that contains information about the specific dependencies for the providers that are installed in this workspace. Also downloads modules you may be using.

Creates state file (`terraform.tfstate`), terraform's representation of the world, a JSON file containing information about every resource and data object. Also contains sensitive information such as DB passwords. Can be stored locally or remotely.

---

### `terraform plan`

Takes Terraform Config (desired state) and compares it to Terraform State (actual state). If there is a mismatch between desired state and actual state, it adds a plan to make the desired changes.

---

### `terraform apply [-auto-approve]`

This will take the plan and feed it to the provider which will figure out the sequence of api calls necessary to make these changes, implementing the plan.

---

### `terraform destroy [-auto-approve]`

This will destroy the Terraform State, minimizes resources used.

---

---

## General - Terraform Coding:

### The Terraform Block:

This configures Terraform itself, including which providers to install, and which version of terraform to use to provision your infrastructure. Using a consistent file structure will make maintaining a Terraform project easier, so it is recommended to configure the Terraform block in a dedicated `terraform.tf` file.

```
# Specifies providers
terraform {

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }

    cloud {

        organization = "static-site"

        workspaces {
        name = "static-site-portfolio"
        }
    }

    required_version = ">=1.13"
}

```

Here, the string `~> 5.92` means this configuration supports any vesion of the provider with a major version of `5` and a minor version greater than or equal to `92`.

This example config also defines the required version of **Terraform**, itself. The string `= >  1.5` means the configuration supports any version of terraform greater than or equal to `1.5`.

The cloud section is telling terraform we're going to use an EC2 instance to actually run terraform (terraform init/plan/apply/destroy). So, using the Terraform Cloud, it will use credentials (which you must provide via variables or a more complicated setup for production level work) to interact with the provider (AWS) and allocate resources.

Alternatively you can use s3 bucket and dynamo DB table, which would change the terraform block to have this instead of the cloud section (with everything actually filled out):

```
backend "s3" {
    bucket          = ""
    key             = ""
    region          = ""
    dynamodb_table  = ""
    encrypt         = true
}
```

This would require us to provision both the s3 bucket and dynamo DB table (bootstrapping). This completely changes our terraform code as we need to define our resources needed, and we will first save our state locally in order to acquire these resources, meaning we will not define a backend on our initial boot, only after the resources are provisioned.

---

---

### Configuration Blocks:

#### _Provider blocks_

Configures options that apply to all resources managed by the provider, such as the region to create them in. The label of the provider block corresponds to the name of the provider in the **required_providers** list in the terraform block.

```
provider "aws" {
  region = "us-west-2"
}
```

Multiple provider blocks can be used to configure multiple providers or multiple instances of the same provider with different configurations, such as a different region.

---

#### _Data blocks_

These blocks are used to query your cloud provider for information about other resources. This data source fetches data about the latest AWS AMI that matches the filter, so you don't have to hardcode the AMI ID into your config. Data sources help keep your configuration dynamic and avoid hardcoded values that can become stale.

```
data "aws_ami" "amazon_linux_2" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
```

Data sources have an ID, which you can use to reference the data attributes within your configuration. Data source IDs are prefixed with **data**, followed by the block's type and name. For the example above, the `data.aws_ami.amazon_linux_2` data source loads an AMI for the most recent AWS Free Tier Amazon Linux 2 AMI.

---

#### _Resource blocks_

These blocks define components of your infrastructure. The following configuration defines a resource block to create an AWS EC2 instance.

```
resource "aws_instance" "ex" {
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  tags = {
    Name = "Free Tier Instance"
  }
}
```

The first line of a resource block declares a resource type and resource name. In this example, the resource type is **"aws_instance"**. The prefix of the resource type corresonds to the name of the provider, and the rest of the string is the provider-defined resource type. Together, the resource type and resource name form a unique **"resource address"** for the resource in your configuration. The resource address for the EC2 instance is aws_instance.ex. This way, you can refer to a resource in other parts of your configuration by its resource address.

> arg: ami - specifies which machine image to use by referencing the data.aws_ami.amazon_linux_2 data source's id attribute

> arg: instance_type - argument ahrdcodes t3.micro as the type, which qualifies for the AWS free tier.

> arg: tags - sets the EC2 instance's name, other options also available.

---

---

## General - Terraform Variables & Outputs

### <ins> Variable Types </ins>

---

#### <ins> _*Input Variables*_ </ins>

- Code Example:
  ```
  variable "instance_type" {
      description = "ec2 instance type"
      type = string
      default = "t2.micro"
  }
  ```
- _Referenced by:_
  ```
  var.<name>
  var.instance_type
  ```

---

#### <ins>_*Local Variables*_</ins>

- Code Example:

  ```
  locals {
      service_name = "My Service"
      owner = "DevOps Directive"
  }
  ```

- _Referenced by:_
  ```
  local.<name>
  local.service_name
  ```

---

#### <ins> _*Output Variables*_</ins>

- Code Example:

  ```
  output "instance_ip_addr" {
      value = aws_instance.instance.public_ip
  }
  ```

- These are like return values of the function, just a way to get specific data

---

---

### <ins>Setting Input Variables </ins>

- In order of precedence // lowest -> highest:
  - Manual entry druing plan/apply
  - Defautl value in declaration block
  - `TF_VAR_<name>` environment variables
  - `terraform.tfvars` file
  - `*.auto.tfvars` file
  - Command line -var or -var-file

---

## General - Terraform Architecture:

![Terraform Architecture](/media/TerraformArchitecture.png)

---

### Terraform State <-> Terraform Core

Contains references to architecture we've already provisioned.

---

### Terraform Config <-> Terraform Core

New configurations we want to add.

---

### Terraform Core -> Providers

The engine that takes our config files with our state file (references to architecture we've already provisioned) and figures out how to interact with the cloud provider apis to make thaat state match teh config we want it to

---

### Providers (AWS/Cloudfare) ->

Kind of like plugins to the core. Tells Terraform how to map a specific configuration onto the current state of the current AWS api (for example). A middle man between Terraform and AWS.

---

---
