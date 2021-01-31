##
#  Mectrics Collection AWS KMS mc-
##

resource "aws_kms_key" "mykey" {
  description               = var.mks-description
  deletion_window_in_days   = 7
  customer_master_key_spec  = "SYMMETRIC_DEFAULT"
  enable_key_rotation = true

  tags = {
    Name                    = var.service_name
    Environment             = var.environment
    (var.billing_tag_key)   = var.billing_tag_value
    Resource                = "KMS"
    Project                 = var.project
    Deployment              = "Terraform"
  }
  policy = <<EOF
{
    "Id": "key-terraform-policy-3",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "${aws_iam_role.role.arn}"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "${aws_iam_role.role.arn}"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
EOF

}

resource "aws_kms_alias" "mykey" {
  name          = "alias/${var.service_name}-key"
  target_key_id = aws_kms_key.mykey.key_id
}

