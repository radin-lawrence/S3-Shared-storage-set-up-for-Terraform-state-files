
# S3 Shared storage set up for Terraform state files

When running the "terraform plan" or "terraform apply" commands you may have noticed that, Terraform was able to find the resources it created previously and update them accordingly. But how did Terraform know which resources it was supposed to manage?

The answer is that Terraform records information about what infrastructure it created in a Terraform state file. By default, when you run Terraform in the folder /var/project, Terraform creates the file /var/project/terraform.tfstate. This file contains a custom JSON format that records a mapping from the Terraform resources in your templates to the representation of those resources in the real world.

Therefore you’re using Terraform for a personal project, storing state in a local terraform.tfstate file works just fine.But if you want to use Terraform as a team on a real product, each of your team members needs access to the same Terraform state files. That means you need to store those files in a shared location.
## Features
 
 - Automatically store the state file in that backend after each "apply", so there’s no chance of manual error. 

-  Backend(S3) supports encryption in transit and encryption on the disk of the state file. 

## Features
 
 - Automatically store the state file in that backend after each "apply", so there’s no chance of manual error. 

-  Backend(S3) supports encryption in transit and encryption on the disk of the state file. 

## Creating an S3 bucket to store Terraform state file

> Note: It is highly recommended that you enable Bucket Versioning on the S3 bucket to allow for state recovery in the case of accidental deletions and human error.

```bash
resource "aws_s3_bucket" "terra" {
  bucket = var.name
    tags = {
    Name        = "${var.project}"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.terra.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enc" {
  bucket = aws_s3_bucket.terra.bucket

  rule {
    apply_server_side_encryption_by_default {
    sse_algorithm     = "AES256"
    }
  }
}

```

**Bucket policy for the S3 bucket**

Terraform will need the following AWS IAM permissions on the target backend bucket:

s3:ListBucket on arn:aws:s3:::mybucket
s3:GetObject on arn:aws:s3:::mybucket/path/to/my/key
s3:PutObject on arn:aws:s3:::mybucket/path/to/my/key
s3:DeleteObject on arn:aws:s3:::mybucket/path/to/my/key

```bash
resource "aws_s3_bucket_policy" "s3_terraform_policy" {
  bucket = aws_s3_bucket.terraform.id
  policy = data.aws_iam_policy_document.terraform_policy.json
}

data "aws_iam_policy_document" "terraform_policy" {
  statement {
    principals {
      type        = "AWS"
    }

   effect = "Allow"
    actions = [
      "s3:ListBucket","s3:GetObject", "s3:PutObject", "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.terraform.arn,
      "${aws_s3_bucket.terraform.arn}/*",
    ]
  }
}

```

> Note: The referenced S3 bucket must have been previously created before setting up the backend.

```bash
 terraform init 

 terrafrom plan

 terrafrom apply
 ```

Once set up the bucket we can set up the backends.
Backends define where Terraform's state snapshots are stored.
Accessing the state in a remote service generally requires some kind of access credentials, since state data contains extremely sensitive information.

```bash
terraform {
  backend "s3" {
    bucket = "mybucket"        
    key    = "path/to/my/key"   #eg:"foo/terraform.tfstate"
    encrypt  = true
  }
}
```

This assumes we have a bucket created called "mybucket". The Terraform state is written to the key path/to/my/key.
Note that for the access credentials we recommend using a [partial configuration](https://www.terraform.io/language/settings/backends/configuration#partial-configuration)

```bash
terraform init -backend-config=./file
```

Terraform will automatically detect that you already have a state file locally and prompt you to copy it to the new S3 backend. If you type in “yes,” you should see:


