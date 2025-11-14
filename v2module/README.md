## General - Meta-Arguments

### `depends_on`
---
- Terraform automatically generates dependency graph based on references

- If two resources depend on each other (but not each others data), `depends_on` specifies that dependency to enforce ordering.

- For example, if software on the instance needs access to S3, trying to create the _aws_instance_ would fail if attempting to create it before the _aws_iam_role_policy_

### `count`
---

- Allows for creation of multiple resources/modules from a single block

- Useful when the multiple necessary resources are nearly identical

- Example:

    ```
    resource "aws_instance" "server" {
        count = 4 # Create four EC2 instances

        ami = "some ami instance"
        instance_type = "some instance type"

        tags = {
            Name = "Server ${count.index}"
        }
    }
    ```

### `for_each`
---

- Allows for creation of multiple resources/modules from a single block

- Allows more control to customize each resource than `count`

- Example:
    ```
    locals {
        subnet_ids = toset([
            "subnet-blah",
            "subnet-blahblah",
        ])
    }

    resource "aws_instance" "server" {
        for_each = local.subnet_ids

        ami = "some ami"
        instance_type = "some instance type"
        subnet_id = each.key

        tags = {
            Name = "Server ${each.key}"
        }
    }
    ```
    
### Lifecycle
---

- A set of meta arguments to control terraform behavior for specific resources

- _create_before_destroy_ can help with zero downtime deployments

- _ignore_changes_ prevents Terraform from trying to revert metadata being set elsewhere

- _prevent_destroy_ causes Terraform to reject any plan which would destroy this resource

## General - Provisioners

- Allows you to perform action on local or remote machines

- Types: file, local-exec, remote-exec, vendor (chef, puppet)


---
## General - Modules

- Def: containers for multiple resources that are used together. A module consists of a collection of .tf and/or .tf.json files kept together in a directory.

- Main way to package and reuse resource configurations with Terraform.

---
**Types of Modules**

- **Root Module** : Default module containing all .tf files in main working directory

- **Child Module** : A separate external module referred to from a .tf file

---

**Module Sources**

- Local paths
    - Ex:
        ```
        module "web-app" {
            source = "../web-app"
        }
        ```

- Terraform Registry (like providers)
    - Ex:
        ```
        module "consul" {
            source = "hashicorp/consul/aws"
            version = "0.1.0
        }
        ```
- GitHub
    - HTTPS with specified version v1.2.0; Ex:
        ```
        module "example" {
            source = "github.com/hashicorp/example?ref=v1.2.0"
        }
        ```
    - SSH Ex:
        ```
        module "example" {
            source = "git@github.com:hashicorp/example.git"
        }
        ```
- Generic Git, Mercurial repos
    - Generic Ex:
        ```
        module "example" {
            source = "git::ssh://username@example.com/storage.git"
        }
        ```
- Bitbucket
- HTTP URLS
- S3 buckets
- GCS buckets

---
**Inputs + Meta-arguments**
-

- Input variables are passed via module block

- Ex:
    ```
    module "web_app" {
        source = "../web-app-module"

        # input variables
        bucket_name = "devops-directive-web-app-data"
        domain = "site.com"
        db_name = "name"
        db_user = "user"
        db_pass = "var.db_pass
    }
    ```

    **Meta-Arguments** : used to make multiple resources via the block
    - `count`
    - `for_each`
    - providers
    - depends_on