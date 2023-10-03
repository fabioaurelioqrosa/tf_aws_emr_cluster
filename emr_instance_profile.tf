# Role creation and assumption
data "aws_iam_policy_document" "emr_instance_profile_assume_role" {

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "emr_instance_profile" {

  count = var.create_instance_profile ? 1 : 0 

  name               = "AmazonEMR-InstanceProfile-${var.name}"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.emr_instance_profile_assume_role.json

}

resource "aws_iam_policy" "emr_instance_profile" {

  count = var.create_instance_profile ? 1 : 0 

  name        = "AmazonEMR-InstanceProfile-Policy-${var.name}"
  description = "EMR Instance Profile"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:CreateBucket",
                "s3:DeleteObject",
                "s3:GetBucketVersioning",
                "s3:GetObject",
                "s3:GetObjectTagging",
                "s3:GetObjectVersion",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListBucketVersions",
                "s3:ListMultipartUploadParts",
                "s3:PutBucketVersioning",
                "s3:PutObject",
                "s3:PutObjectTagging"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_profile_policy_attachment" {

  role       = aws_iam_role.emr_instance_profile[0].name
  policy_arn = aws_iam_policy.emr_instance_profile[0].arn

}

resource "aws_iam_role_policy_attachment" "AmazonElasticMapReduceforEC2Role" {
  
  role       = aws_iam_role.emr_instance_profile[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"

}
/*
resource "aws_iam_role_policy_attachment" "AWSEC2FleetServiceRolePolicy" {

  role       = aws_iam_role.emr_instance_profile[0].name
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AWSEC2FleetServiceRolePolicy"

}*/

resource "aws_iam_instance_profile" "emr" {
  
  count = var.create_instance_profile ? 1 : 0 

  name = "AmazonEMR-InstanceProfile-${var.name}"
  role = aws_iam_role.emr_instance_profile[0].name
}
