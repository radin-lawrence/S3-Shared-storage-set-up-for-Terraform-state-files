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

resource "aws_s3_bucket_policy" "s3_terraform_policy" {
  bucket = aws_s3_bucket.terraform.id
  policy = data.aws_iam_policy_document.terraform_policy.json
}

data "aws_iam_policy_document" "terraform_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
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






terraform {
  backend "s3" {
    bucket = "mybucket"        
    key    = "path/to/my/key"   #eg:"foo/terraform.tfstate"
    encrypt  = true
  }
}
