provider "aws" {
    region = "eu-west-2"
}



# create bucket for uploading files to. Configure Cors permissions.

resource "aws_s3_bucket" "upload_bucket_terraform" {
    bucket = "terraform-upload-bucket"

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT", "POST"]
        #allowed_origins = ["http://jen-terraform-hosting-bucket.s3-website.eu-west-2.amazonaws.com/"]
        allowed_origins = ["*"]
        expose_headers = []
    }

}



# block public access on upload bucket

resource "aws_s3_bucket_public_access_block" "example" {
    bucket = aws_s3_bucket.upload_bucket_terraform.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}



# create bucket for hosting files

resource "aws_s3_bucket" "terraform_hosting_bucket" {
  bucket = "jen-terraform-hosting-bucket"

  acl = "public-read"

  website {
      index_document = "index.html"
  }

}

#add bucket policy to hosting bucket so public can access web page

resource "aws_s3_bucket_policy" "get_object_policy" {
    bucket = aws_s3_bucket.terraform_hosting_bucket.id

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "MYBUCKETPOLICY",
    "Statement": [
        {
            "Sid": "allow_hosting",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::jen-terraform-hosting-bucket/*"
        }
    ]
}
POLICY
}




#create IAM group

resource "aws_iam_group" "council_iam_group_terraform" {
    name = "iam_group_council_terraform"
    path = "/"

}



#attach new write only policy to IAM group

resource "aws_iam_group_policy" "council_policy_terraform" {
    name = "council_policy_terraform"
    group = aws_iam_group.council_iam_group_terraform.name

    policy = <<EOF
{
    "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::terraform-upload-bucket/*"
        }
    ]
    }
    EOF
}



#create user (i.e. a council)

resource "aws_iam_user" "terraform_user_council" {
    name = "terraform_councilA"
}



# attach user to IAM group

resource "aws_iam_group_membership" "team" {
    name = "terraform-group-membership"

    users = [aws_iam_user.terraform_user_council.name]
    group = aws_iam_group.council_iam_group_terraform.name
}



#create access key for user to be able to upload to bucket

resource "aws_iam_access_key" "key" {
  user    = aws_iam_user.terraform_user_council.name
}



#upload index.html to hosting bucket

resource "aws_s3_bucket_object" "host_index" {
    bucket = aws_s3_bucket.terraform_hosting_bucket.id
    key = "index.html"
    source = "./index.html"
    content_type = "text/html"

}





/* Cant figure out how to add access key to index fiole to allow upload from webpage


output "user_credentials" {
  value = { "name"="${aws_iam_user.terraform_user_council.name}", "key-id"="${aws_iam_access_key.key.id}" , "key-secret" = "${aws_iam_access_key.key.secret}" }
}


resource "local_file" "key-secret" {
    content  = aws_iam_access_key.key.secret
    filename = "key-secret.json"
}


resource "local_file" "key-id" {
    content  = "{key-id: ${aws_iam_access_key.key.id}}"
    filename = "key-id.json"
}

*/