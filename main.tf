resource "aws_emr_cluster" "cluster" {
  name                              = var.name
  release_label                     = var.release_label
  service_role                      = var.service_role_arn
  additional_info                   = var.additional_info
  applications                      = var.applications
  autoscaling_role                  = var.autoscaling_role
  configurations_json               = var.configurations_json
  custom_ami_id                     = var.custom_ami_id
  ebs_root_volume_size              = var.ebs_root_volume_size
  keep_job_flow_alive_when_no_steps = var.keep_job_flow_alive_when_no_steps
  log_encryption_kms_key_id         = var.log_encryption_kms_key_id
  log_uri                           = var.log_uri
  scale_down_behavior               = var.scale_down_behavior
  security_configuration            = var.security_configuration
  step_concurrency_level            = var.step_concurrency_level
  termination_protection            = var.termination_protection
  visible_to_all_users              = var.visible_to_all_users

  ## An auto-termination policy for an Amazon EMR cluster. An auto-termination policy defines the amount of idle time
  ## in seconds after which a cluster automatically terminates. 
  dynamic "auto_termination_policy" {

    # Check if "Auto Termination Policy" is defined
    for_each = var.auto_termination_policy == null ? [] : [1]

    #  Specifies the amount of idle time in seconds after which the cluster automatically terminates. You can specify
    #  a minimum of 60 seconds and a maximum of 604800 seconds (seven days).
    content {
      idle_timeout = var.auto_termination_policy.idle_timeout
    }
  }


  ## Ordered list of bootstrap actions that will be run before Hadoop is started on the cluster nodes. 
  dynamic "bootstrap_action" {

    # Check if "Bootstrap Actions" is defined. If it's defined, iterate over the array to get each bootstrap action.
    for_each = var.bootstrap_action == null ? [] : [size(var.bootstrap_action)]

    content {
      path = bootstrap_action.value["path"]
      name = bootstrap_action.value["name"]
      args = bootstrap_action.value["args"]
    }

  }


  ## Configuration block to use an Instance Group for the core node type.
  dynamic "core_instance_group" {

    # Check if "Bootstrap Actions" is defined. If it's defined, iterate over the array to get each bootstrap action.
    for_each = var.core_instance_group == null ? [] : [1]

    content {
      instance_type  = var.core_instance_group.instance_type
      instance_count = var.core_instance_group.instance_count
      name           = var.core_instance_group.name
      bid_price      = var.core_instance_group.bid_price

      # Check if "EBS Config" is defined. If it's defined, iterate over the array to get each EBS config.
      dynamic "ebs_config" {
        for_each = var.core_instance_group.ebs_config == null ? [] : [1]
        content {
          type                 = var.core_instance_group.ebs_config.type
          size                 = var.core_instance_group.ebs_config.size
          iops                 = var.core_instance_group.ebs_config.iops
          throughput           = var.core_instance_group.ebs_config.throughput
          volumes_per_instance = var.core_instance_group.ebs_config.volumes_per_instance
        }
      }
    }
  }


  ## Configuration block to use an Instance Group for the master node type.
  dynamic "master_instance_group" {

    # Check if "Bootstrap Actions" is defined. If it's defined, iterate over the array to get each bootstrap action.
    for_each = var.master_instance_group == null ? [] : [1]

    content {
      instance_type  = var.master_instance_group.instance_type
      instance_count = var.master_instance_group.instance_count
      name           = var.master_instance_group.name
      bid_price      = var.master_instance_group.bid_price

      # Check if "EBS Config" is defined. If it's defined, iterate over the array to get each EBS config.
      dynamic "ebs_config" {
        for_each = var.master_instance_group.ebs_config == null ? [] : [1]
        content {
          type                 = var.master_instance_group.ebs_config.type
          size                 = var.master_instance_group.ebs_config.size
          iops                 = var.master_instance_group.ebs_config.iops
          throughput           = var.master_instance_group.ebs_config.throughput
          volumes_per_instance = var.master_instance_group.ebs_config.volumes_per_instance
        }
      }
    }
  }


  ## Attributes for the EC2 instances running the job flow.
  dynamic "ec2_attributes" {

    # Check if "Bootstrap Actions" is defined. If it's defined, iterate over the array to get each bootstrap action.
    for_each = var.ec2_attributes == null ? [] : [1]

    content {
      instance_profile                  = var.ec2_attributes.instance_profile                  # Instance Profile for EC2 instances of the cluster assume this role.
      additional_master_security_groups = var.ec2_attributes.additional_master_security_groups # String containing a comma separated list of additional Amazon EC2 security group IDs for the master node.
      additional_slave_security_groups  = var.ec2_attributes.additional_slave_security_groups  # String containing a comma separated list of additional Amazon EC2 security group IDs for the slave nodes as a comma separated string.
      emr_managed_master_security_group = var.ec2_attributes.emr_managed_master_security_group # Identifier of the Amazon EC2 EMR-Managed security group for the master node.
      emr_managed_slave_security_group  = var.ec2_attributes.emr_managed_slave_security_group  # Identifier of the Amazon EC2 EMR-Managed security group for the slave nodes.
      key_name                          = var.ec2_attributes.key_name                          # Amazon EC2 key pair that can be used to ssh to the master node as the user called hadoop.
      service_access_security_group     = var.ec2_attributes.service_access_security_group     # Identifier of the Amazon EC2 service-access security group - required when the cluster runs on a private subnet.
      subnet_id                         = var.ec2_attributes.subnet_id                         # VPC subnet id where you want the job flow to launch. Cannot specify the cc1.4xlarge instance type for nodes of a job flow launched in an Amazon VPC.
    }
  }

  ## Ordered list of bootstrap actions that will be run before Hadoop is started on the cluster nodes. 
  dynamic "step" {

    # Check if "Bootstrap Actions" is defined. If it's defined, iterate over the array to get each bootstrap action.
    for_each = var.step == null ? [] : [size(var.step)]

    content {
      action_on_failure = step.value["action_on_failure"]
      name              = step.value["name"]
      hadoop_jar_step = {
        jar = step.value["hadoop_jar_step"].jar
      }
    }

  }
}