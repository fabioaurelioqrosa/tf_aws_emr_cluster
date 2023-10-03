locals {
  security_group_names = ["Master", "Slave"]
  security_group_descs = ["EMR Master Security Group", "EMR Slave Security Group"]

  tags = {
    
  }
}

# Create Security Groups "Master" and "Slave"
resource "aws_security_group" "emr" {

  count = length(local.security_group_names)

  vpc_id      = data.aws_vpc.emr.id
  name        = local.security_group_names[count.index]
  description = local.security_group_descs[count.index]

  tags = merge(
    local.tags,
    {
      "Name" = local.security_group_names[count.index]
      # https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-managed-iam-policies.html#manually-tagged-resources
      "for-use-with-amazon-emr-managed-policies" = true
    },
  )
}

# Add ingress rule for Master
resource "aws_security_group_rule" "pl-f8bd5e91" {
  type              = "ingress"
  security_group_id = aws_security_group.emr[0].id
  from_port         = 8443
  to_port           = 8443
  protocol          = "TCP"
  prefix_list_ids   = ["pl-f8bd5e91"] # com.amazonaws.firewall.regional-prod-only
}

# Allow all traffic from all machines from the same group
resource "aws_security_group_rule" "self" {

  count = length(local.security_group_names)

  type              = "ingress"
  security_group_id = aws_security_group.emr[count.index].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

# Allow all traffic from the other group to this one
resource "aws_security_group_rule" "other" {

  count = length(local.security_group_names)

  type                     = "ingress"
  security_group_id        = aws_security_group.emr[count.index].id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = count.index == 0 ? aws_security_group.emr[1].id : aws_security_group.emr[0].id
}

# Allow all egress traffic
resource "aws_security_group_rule" "egress" {

  count = length(local.security_group_names)

  type                     = "egress"
  security_group_id        = aws_security_group.emr[count.index].id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
}
