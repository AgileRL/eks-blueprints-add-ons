data "aws_iam_policy" "ReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role" "backup" {
  name = "${var.cluster_name}-backup"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-readonly-role-policy-attach" {
  # FIXME spilo need access to metadata
  role       = "${aws_iam_role.backup.name}"
  policy_arn = "${data.aws_iam_policy.ReadOnlyAccess.arn}"
}


data "aws_eks_node_groups" "this" {
  cluster_name    = var.cluster_name
}

data "aws_eks_node_group" "this" {
  for_each = data.aws_eks_node_groups.this.names

  cluster_name    = var.cluster_name
  node_group_name = each.value
}

data "aws_iam_roles" "this" {
  name_regex = ".*eks-node-group-.*"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = data.aws_iam_roles.this.arns
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = data.aws_iam_roles.this.arns
    }

    actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}


module "s3_backups" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket_name

  create_bucket = true
  control_object_ownership = true
  object_ownership = "ObjectWriter"

  acl = "private"

  # Bucket policies
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json
  attach_deny_insecure_transport_policy    = true
  attach_require_latest_tls_policy         = true
  attach_deny_incorrect_encryption_headers = true
  # attach_deny_incorrect_kms_key_sse        = true

  tags = var.tags
}

