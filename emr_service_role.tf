# Role creation and assumption
data "aws_iam_policy_document" "emr_assume_role" {

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "emr_service_role" {

  count = var.create_service_role ? 1 : 0 

  name                  = "AmazonEMR-ServiceRole-${var.name}"
  path                  = "/service-role/"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.emr_assume_role.json

  tags = merge(
    local.tags,
    # https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-managed-iam-policies.html#manually-tagged-resources
    { "for-use-with-amazon-emr-managed-policies" = true },
  )

}


# Role statements
data "aws_iam_policy_document" "emr_service_role_policy_statements" {

  statement {
    sid       = "CreateInNetwork"
    effect    = "Allow"
    actions   = [
      "ec2:CreateNetworkInterface", 
      "ec2:RunInstances", 
      "ec2:CreateFleet", 
      "ec2:CreateLaunchTemplate", 
      "ec2:CreateLaunchTemplateVersion"
    ]
    resources = [
      "arn:aws:ec2:*:*:subnet/${data.aws_subnet.emr.id}", 
      "arn:aws:ec2:*:*:security-group/${aws_security_group.emr[0].id}", 
      "arn:aws:ec2:*:*:security-group/${aws_security_group.emr[1].id}"]
  }

  statement {
    sid       = "ManageSecurityGroups"
    effect    = "Allow"
    actions   = [
      "ec2:AuthorizeSecurityGroupEgress", 
      "ec2:AuthorizeSecurityGroupIngress", 
      "ec2:RevokeSecurityGroupEgress", 
      "ec2:RevokeSecurityGroupIngress"
    ]    
    resources = [
      "arn:aws:ec2:*:*:security-group/${aws_security_group.emr[0].id}", 
      "arn:aws:ec2:*:*:security-group/${aws_security_group.emr[1].id}"
    ]
  }

  statement {
    sid       = "CreateDefaultSecurityGroupInVPC"
    effect    = "Allow"
    actions   = [
      "ec2:CreateSecurityGroup"
    ]    
    resources = [
      "arn:aws:ec2:*:*:vpc/${data.aws_vpc.emr.id}"
    ]
  }

  statement {
    sid       = "PassRoleForEC2"
    effect    = "Allow"
    actions   = ["iam:PassRole"]    
    resources = [aws_iam_role.emr_instance_profile[0].arn]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }

  }
}

/**/

resource "aws_iam_policy" "emr_service_role_policy" {

  name   = "AmazonEMR-ServiceRole-Policy-${var.name}"
  policy = data.aws_iam_policy_document.emr_service_role_policy_statements.json

}



# Attach policies
resource "aws_iam_role_policy_attachment" "emr_service_police" {

  count = var.create_service_role ? 1 : 0

  role       = aws_iam_role.emr_service_role[0].name
  policy_arn = aws_iam_policy.emr_service_role_policy.arn

}

resource "aws_iam_role_policy_attachment" "policy_attachment" {

  count = var.create_service_role ? 1 : 0

  role       = aws_iam_role.emr_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"

}

