# Create a user group
resource "aws_iam_group" "dev-group" {
  name = "dev-group"
}
# Create IAM Policy for group
resource "aws_iam_policy" "DevPolicy" {
  name = "DevPolicy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "ec2:*",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "ec2:ResourceTag/Env" : "dev"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:Describe*",
        "Resource" : "*"
      },
      {
        "Effect" : "Deny",
        "Action" : [
          "ec2:DeleteTags",
          "ec2:CreateTags"
        ],
        "Resource" : "*"
      }
    ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "dev-attach" {
  group      = aws_iam_group.dev-group.name
  policy_arn = aws_iam_policy.DevPolicy.arn
}

# Create IAM User
resource "aws_iam_user" "dev-user" {
  name          = "dev-user"
  force_destroy = true
}

resource "aws_iam_group_membership" "devstream" {
  name  = aws_iam_user.dev-user.name
  users = [aws_iam_user.dev-user.name]
  group = aws_iam_group.dev-group.name
}



########

# Create First Bucket
resource "aws_s3_bucket" "chinmayto-s3" {
  bucket = "chinmayto-s3"
}

resource "aws_s3_bucket_object" "object1" {
  for_each = fileset("uploads/", "*")
  bucket   = aws_s3_bucket.chinmayto-s3.id
  key      = each.value
  source   = "uploads/${each.value}"
}

# Create Second Bucket

resource "aws_s3_bucket" "chinmayto-s3-other" {
  bucket = "chinmayto-s3-other"
}

resource "aws_s3_bucket_object" "object2" {
  for_each = fileset("uploads/", "*")
  bucket   = aws_s3_bucket.chinmayto-s3-other.id
  key      = each.value
  source   = "uploads/${each.value}"
}


# Create policy for role
resource "aws_iam_policy" "IAMBucketTestPolicy" {
  name = "IAMBucketTestPolicy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : [
          "arn:aws:s3:::chinmayto-s3/*",
          "arn:aws:s3:::chinmayto-s3"
        ]
      }
    ]
    }
  )
}


# Create a role that can be assumed by an Amazon EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the role to the policy
resource "aws_iam_role_policy_attachment" "example_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.IAMBucketTestPolicy.arn
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}