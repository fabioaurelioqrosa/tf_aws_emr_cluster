variable "account_id" {
  type    = string
}

variable "region_id" {
  type    = string
}

variable "vpc_name" {
  type    = string
  default = null
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "subnet_name" {
  type    = string
  default = null
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "create_security_group" {
  type    = bool
  default = true
}

variable "security_group_id" {
  type    = string
  default = null
}

variable "create_service_role" {
  type    = bool
  default = true
}

variable "create_instance_profile" {
  type    = bool
  default = true
}

variable "availability_zone" {
  description = "(Required) The availability zone where the instance is going to be launched in."
  type        = string
  default     = null
}

variable "name" {
  description = "(Required) Specifies the name of the product. Changing this forces a new resource to be created."
  type        = string
  default     = "cluster"
}

variable "release_label" {
  description = "(Required) Release label for the Amazon EMR release"
  type        = string
  default     = "emr-5.36.0"
}

variable "service_role_arn" {
  description = "(Required) IAM role that will be assumed by the Amazon EMR service to access AWS resources."
  type        = string
  default     = null
}

variable "additional_info" {
  description = "(Optional) JSON string for selecting additional features such as adding proxy information. NOTE: Currently there is no API to retrieve the value of this argument after EMR cluster creation from provider, therefore Terraform cannot detect drift from the actual EMR cluster if its value is changed outside Terraform."
  type        = string
  default     = null
}

variable "applications" {
  description = "(Optional) A case-insensitive list of applications for Amazon EMR to install and configure when launching the cluster. For a list of applications available for each Amazon EMR release version, see the Amazon EMR Release Guide. https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-release-components.html"
  type        = list(string)
  default     = ["spark", "hbase", "hive"]
}

variable "autoscaling_role" {
  description = "(Optional) IAM role for automatic scaling policies. The IAM role provides permissions that the automatic scaling feature requires to launch and terminate EC2 instances in an instance group."
  type        = string
  default     = null
}

variable "auto_termination_policy" {
  description = "(Optional) An auto-termination policy for an Amazon EMR cluster. An auto-termination policy defines the amount of idle time in seconds after which a cluster automatically terminates. See Auto Termination Policy Below."
  type = object({
    idle_timeout = optional(number, null) # (Optional) Specifies the amount of idle time in seconds after which the cluster automatically terminates. You can specify a minimum of 60 seconds and a maximum of 604800 seconds (seven days).
  })
  default = null
}

variable "bootstrap_action" {
  description = "(Optional) Ordered list of bootstrap actions that will be run before Hadoop is started on the cluster nodes. See below."
  type = list(object({
    name = string                 # (Required) Name of the bootstrap action.
    path = string                 # (Required) Location of the script to run during a bootstrap action. Can be either a location in Amazon S3 or on a local file system.
    args = optional(list(string)) # (Optional) List of command line arguments to pass to the bootstrap action script.
  }))
  default = null
}

/*
variable "configurations" {
  description = "(Optional) List of configurations supplied for the EMR cluster you are creating. Supply a configuration object for applications to override their default configuration. See AWS Documentation for more information: https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html"
  type        = list(object({
    classification = string      # (Optional) Classification within a configuration.
    properties     = map(string) # (Optional) Map of properties specified within a configuration classification.
  }))
  default     = null
}*/

variable "configurations_json" {
  description = "(Optional) JSON string for supplying list of configurations for the EMR cluster."
  type        = string
  default     = null
}

variable "core_instance_fleet" {
  description = "(Optional) Configuration block to use an Instance Fleet for the core node type. Cannot be specified if any 'core_instance_group' configuration blocks are set. Detailed below."
  type = object({
    name                      = optional(string) # (Optional) Friendly name given to the instance fleet.
    target_on_demand_capacity = optional(number) # (Optional) Target capacity of On-Demand units for the instance fleet, which determines how many On-Demand instances to provision.
    target_spot_capacity      = optional(string) # (Optional) Target capacity of Spot units for the instance fleet, which determines how many Spot instances to provision.
    instance_type_configs = object({
      instance_type                              = string           # (Required) EC2 instance type, such as m4.xlarge.
      bid_price                                  = optional(string) # (Optional) Bid price for each EC2 Spot instance type as defined by instance_type. Expressed in USD. If neither bid_price nor bid_price_as_percentage_of_on_demand_price is provided, bid_price_as_percentage_of_on_demand_price defaults to 100%.
      bid_price_as_percentage_of_on_demand_price = optional(number) # (Optional) Bid price, as a percentage of On-Demand price, for each EC2 Spot instance as defined by instance_type. Expressed as a number (for example, 20 specifies 20%). If neither bid_price nor bid_price_as_percentage_of_on_demand_price is provided, bid_price_as_percentage_of_on_demand_price defaults to 100%.
      weighted_capacity                          = optional(number) # (Optional) Number of units that a provisioned instance of this type provides toward fulfilling the target capacities defined in aws_emr_instance_fleet.
      configurations = optional(list(object({                       # (Optional) A configuration classification that applies when provisioning cluster instances, which can include configurations for applications and software that run on the cluster. See Configuring Applications: https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html
        classification = string                                     # (Optional) Classification within a configuration.
        properties     = optional(map(string))                      # (Optional) Map of properties specified within a configuration classification.
      })))
      ebs_config = object({
        type                 = string           # Volume type. Valid options are gp3, gp2, io1, standard, st1 and sc1. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumetypes.html 
        size                 = number           # Volume size, in gibibytes (GiB).
        iops                 = optional(number) # Number of I/O operations per second (IOPS) that the volume supports.
        throughput           = optional(number) # The throughput, in mebibyte per second (MiB/s).
        volumes_per_instance = optional(number) # Number of EBS volumes with this configuration to attach to each EC2 instance in the instance group (default is 1).
      })
    })
    launch_specifications = object({
      on_demand_specification = object({ # The launch specification for On-Demand instances in the instance fleet, which determines the allocation strategy. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. On-Demand instances allocation strategy is available in Amazon EMR version 5.12.1 and later.
        allocation_strategy = string     # (Required) Specifies the strategy to use in launching On-Demand instance fleets. Currently, the only option is 'lowest-price' (the default), which launches the lowest price first.
      })
      spot_specification = object({                 # The launch specification for Spot instances in the fleet, which determines the defined duration, provisioning timeout behavior, and allocation strategy.
        allocation_strategy      = string           # (Required) Specifies the strategy to use in launching Spot instance fleets. Currently, the only option is capacity-optimized (the default), which launches instances from Spot instance pools with optimal capacity for the number of instances that are launching.
        timeout_action           = string           # (Required) Action to take when TargetSpotCapacity has not been fulfilled when the TimeoutDurationMinutes has expired; that is, when all Spot instances could not be provisioned within the Spot provisioning timeout. Valid values are TERMINATE_CLUSTER and SWITCH_TO_ON_DEMAND. SWITCH_TO_ON_DEMAND specifies that if no Spot instances are available, On-Demand Instances should be provisioned to fulfill any remaining Spot capacity.
        timeout_duration_minutes = number           # (Required) Spot provisioning timeout period in minutes. If Spot instances are not provisioned within this time period, the TimeOutAction is taken. Minimum value is 5 and maximum value is 1440. The timeout applies only during initial provisioning, when the cluster is first created.
        block_duration_minutes   = optional(number) # (Optional) Defined duration for Spot instances (also known as Spot blocks) in minutes. When specified, the Spot instance does not terminate before the defined duration expires, and defined duration pricing for Spot instances applies. Valid values are 60, 120, 180, 240, 300, or 360. The duration period starts as soon as a Spot instance receives its instance ID. At the end of the duration, Amazon EC2 marks the Spot instance for termination and provides a Spot instance termination notice, which gives the instance a two-minute warning before it terminates.
      })
    })
  })
  default = null
}

variable "core_instance_group" {
  description = "(Optional) Configuration block to use an Instance Group for the core node type."
  type = object({
    instance_type      = string           # EC2 instance type for all instances in the instance group.
    instance_count     = optional(number) # Target number of instances for the instance group. Must be 1 or 3. Defaults to 1.
    name               = optional(string) # Friendly name given to the instance group.
    bid_price          = optional(string) # Bid price for each EC2 instance in the instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances.
    autoscaling_policy = optional(string) # (Optional) String containing the EMR Auto Scaling Policy JSON.
    ebs_config = optional(object({
      type                 = string           # Volume type. Valid options are gp3, gp2, io1, standard, st1 and sc1. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumetypes.html 
      size                 = number           # Volume size, in gibibytes (GiB).
      iops                 = optional(number) # Number of I/O operations per second (IOPS) that the volume supports.
      throughput           = optional(number) # The throughput, in mebibyte per second (MiB/s).
      volumes_per_instance = optional(number) # Number of EBS volumes with this configuration to attach to each EC2 instance in the instance group (default is 1).
    }))
  })
  default = null
}

variable "custom_ami_id" {
  description = "(Optional) Custom Amazon Linux AMI for the cluster (instead of an EMR-owned AMI). Available in Amazon EMR version 5.7.0 and later."
  type        = string
  default     = null
}

variable "ebs_root_volume_size" {
  description = "(Optional) Size in GiB of the EBS root device volume of the Linux AMI that is used for each EC2 instance. Available in Amazon EMR version 4.x and later."
  type        = number
  default     = null
}

variable "ec2_attributes" {
  description = "(Optional) Attributes for the EC2 instances running the job flow. See below."
  type = object({
    instance_profile                  = string           # (Required) Instance Profile for EC2 instances of the cluster assume this role.
    additional_master_security_groups = optional(string) #  String containing a comma separated list of additional Amazon EC2 security group IDs for the master node.
    additional_slave_security_groups  = optional(string) #  String containing a comma separated list of additional Amazon EC2 security group IDs for the slave nodes as a comma separated string.
    emr_managed_master_security_group = optional(string) #  Identifier of the Amazon EC2 EMR-Managed security group for the master node.
    emr_managed_slave_security_group  = optional(string) #  Identifier of the Amazon EC2 EMR-Managed security group for the slave nodes.
    key_name                          = optional(string) #  Amazon EC2 key pair that can be used to ssh to the master node as the user called hadoop.
    service_access_security_group     = optional(string) #  Identifier of the Amazon EC2 service-access security group - required when the cluster runs on a private subnet.
    subnet_id                         = optional(string) #  VPC subnet id where you want the job flow to launch. Cannot specify the cc1.4xlarge instance type for nodes of a job flow launched in an Amazon VPC.
    subnet_ids                        = optional(string) #  List of VPC subnet id-s where you want the job flow to launch. Amazon EMR identifies the best Availability Zone to launch instances according to your fleet specifications.
  })
  default = null
}

variable "keep_job_flow_alive_when_no_steps" {
  description = "(Optional) Switch on/off run cluster with no steps or when all steps are complete (default is 'on')"
  type        = string
  default     = null
}

variable "kerberos_attributes" {
  description = "(Optional) Kerberos configuration for the cluster. See below."
  type = object({
    kdc_admin_password                   = string           # (Required) Password used within the cluster for the kadmin service on the cluster-dedicated KDC, which maintains Kerberos principals, password policies, and keytabs for the cluster. Terraform cannot perform drift detection of this configuration.
    realm                                = string           # (Required) Name of the Kerberos realm to which all nodes in a cluster belong. For example, EC2.INTERNAL
    ad_domain_join_password              = optional(string) #  Active Directory password for ad_domain_join_user. Terraform cannot perform drift detection of this configuration.
    ad_domain_join_user                  = optional(string) #  Required only when establishing a cross-realm trust with an Active Directory domain. A user with sufficient privileges to join resources to the domain. Terraform cannot perform drift detection of this configuration.
    cross_realm_trust_principal_password = optional(string) #  Required only when establishing a cross-realm trust with a KDC in a different realm. The cross-realm principal password, which must be identical across realms. Terraform cannot perform drift detection of this configuration.
  })
  default = null
}

variable "list_steps_states" {
  description = "(Optional) List of step states used to filter returned steps."
  type        = list(string)
  default     = null
}

variable "log_encryption_kms_key_id" {
  description = "(Optional) AWS KMS customer master key (CMK) key ID or arn used for encrypting log files. This attribute is only available with EMR version 5.30.0 and later, excluding EMR 6.0.0."
  type        = string
  default     = null
}

variable "log_uri" {
  description = "(Optional) S3 bucket to write the log files of the job flow. If a value is not provided, logs are not created."
  type        = string
  default     = null
}

variable "master_instance_fleet" {
  description = "(Optional) Configuration block to use an Instance Fleet for the master node type. Cannot be specified if any master_instance_group configuration blocks are set. Detailed below."
  type = object({
    name                      = optional(string) # (Optional) Friendly name given to the instance fleet.
    target_on_demand_capacity = optional(number) # (Optional) Target capacity of On-Demand units for the instance fleet, which determines how many On-Demand instances to provision.
    target_spot_capacity      = optional(string) # (Optional) Target capacity of Spot units for the instance fleet, which determines how many Spot instances to provision.
    instance_type_configs = optional(object({
      instance_type                              = string           # (Required) EC2 instance type, such as m4.xlarge.
      bid_price                                  = optional(string) # (Optional) Bid price for each EC2 Spot instance type as defined by instance_type. Expressed in USD. If neither bid_price nor bid_price_as_percentage_of_on_demand_price is provided, bid_price_as_percentage_of_on_demand_price defaults to 100%.
      bid_price_as_percentage_of_on_demand_price = optional(number) # (Optional) Bid price, as a percentage of On-Demand price, for each EC2 Spot instance as defined by instance_type. Expressed as a number (for example, 20 specifies 20%). If neither bid_price nor bid_price_as_percentage_of_on_demand_price is provided, bid_price_as_percentage_of_on_demand_price defaults to 100%.
      weighted_capacity                          = optional(number) # (Optional) Number of units that a provisioned instance of this type provides toward fulfilling the target capacities defined in aws_emr_instance_fleet.
      configurations = optional(list(object({                       # (Optional) A configuration classification that applies when provisioning cluster instances, which can include configurations for applications and software that run on the cluster. See Configuring Applications: https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html
        classification = string                                     # (Optional) Classification within a configuration.
        properties     = optional(map(string))                      # (Optional) Map of properties specified within a configuration classification.
      })))
      ebs_config = object({
        type                 = string           # Volume type. Valid options are gp3, gp2, io1, standard, st1 and sc1. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumetypes.html 
        size                 = number           # Volume size, in gibibytes (GiB).
        iops                 = optional(number) # Number of I/O operations per second (IOPS) that the volume supports.
        throughput           = optional(number) # The throughput, in mebibyte per second (MiB/s).
        volumes_per_instance = optional(number) # Number of EBS volumes with this configuration to attach to each EC2 instance in the instance group (default is 1).
      })
    }))
    launch_specifications = optional(object({
      on_demand_specification = object({ # The launch specification for On-Demand instances in the instance fleet, which determines the allocation strategy. The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. On-Demand instances allocation strategy is available in Amazon EMR version 5.12.1 and later.
        allocation_strategy = string     # (Required) Specifies the strategy to use in launching On-Demand instance fleets. Currently, the only option is 'lowest-price' (the default), which launches the lowest price first.
      })
      spot_specification = object({                 # The launch specification for Spot instances in the fleet, which determines the defined duration, provisioning timeout behavior, and allocation strategy.
        allocation_strategy      = string           # (Required) Specifies the strategy to use in launching Spot instance fleets. Currently, the only option is capacity-optimized (the default), which launches instances from Spot instance pools with optimal capacity for the number of instances that are launching.
        timeout_action           = string           # (Required) Action to take when TargetSpotCapacity has not been fulfilled when the TimeoutDurationMinutes has expired; that is, when all Spot instances could not be provisioned within the Spot provisioning timeout. Valid values are TERMINATE_CLUSTER and SWITCH_TO_ON_DEMAND. SWITCH_TO_ON_DEMAND specifies that if no Spot instances are available, On-Demand Instances should be provisioned to fulfill any remaining Spot capacity.
        timeout_duration_minutes = number           # (Required) Spot provisioning timeout period in minutes. If Spot instances are not provisioned within this time period, the TimeOutAction is taken. Minimum value is 5 and maximum value is 1440. The timeout applies only during initial provisioning, when the cluster is first created.
        block_duration_minutes   = optional(number) # (Optional) Defined duration for Spot instances (also known as Spot blocks) in minutes. When specified, the Spot instance does not terminate before the defined duration expires, and defined duration pricing for Spot instances applies. Valid values are 60, 120, 180, 240, 300, or 360. The duration period starts as soon as a Spot instance receives its instance ID. At the end of the duration, Amazon EC2 marks the Spot instance for termination and provides a Spot instance termination notice, which gives the instance a two-minute warning before it terminates.
      })
    }))
  })
  default = null
}

variable "master_instance_group" {
  description = "(Optional) Configuration block to use an Instance Group for the master node type."
  type = object({
    instance_type  = string           # EC2 instance type for all instances in the instance group.
    instance_count = optional(number) # Target number of instances for the instance group. Must be 1 or 3. Defaults to 1.
    name           = optional(string) # Friendly name given to the instance group.
    bid_price      = optional(string) # Bid price for each EC2 instance in the instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances.
    ebs_config = optional(object({
      type                 = string           # Volume type. Valid options are gp3, gp2, io1, standard, st1 and sc1. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumetypes.html 
      size                 = number           # Volume size, in gibibytes (GiB).
      iops                 = optional(number) # Number of I/O operations per second (IOPS) that the volume supports.
      throughput           = optional(number) # The throughput, in mebibyte per second (MiB/s).
      volumes_per_instance = optional(number) # Number of EBS volumes with this configuration to attach to each EC2 instance in the instance group (default is 1).
    }))
  })
  default = null
}

variable "placement_group_config" {
  description = "(Optional) The specified placement group configuration for an Amazon EMR cluster."
  type = object({
    instance_role      = string           # (Required) Role of the instance in the cluster. Valid Values: 'MASTER', 'CORE', 'TASK'.
    placement_strategy = optional(string) # (Optional) EC2 Placement Group strategy associated with instance role. Valid Values: 'SPREAD', 'PARTITION', 'CLUSTER', 'NONE'.
  })
  default = null
}

variable "scale_down_behavior" {
  description = "(Optional) Way that individual Amazon EC2 instances terminate when an automatic scale-in activity occurs or an instance group is resized."
  type        = string
  default     = null
}

variable "security_configuration" {
  description = "(Optional) Security configuration name to attach to the EMR cluster. Only valid for EMR clusters with release_label 4.8.0 or greater."
  type        = string
  default     = null
}

variable "step" {
  description = "(Optional) List of steps to run when creating the cluster. See below. It is highly recommended to utilize the lifecycle configuration block with ignore_changes if other steps are being managed outside of Terraform. This argument is processed in attribute-as-blocks mode: https://developer.hashicorp.com/terraform/language/v1.3.x/attr-as-blocks"
  type = list(object({
    name              = string            # (Required) Name of the step.
    action_on_failure = string            # (Required) Action to take if the step fails. Valid values: 'TERMINATE_JOB_FLOW', 'TERMINATE_CLUSTER', 'CANCEL_AND_WAIT', and 'CONTINUE'
    hadoop_jar_step = object({            # (Required) JAR file used for the step. See below.
      jar        = string                 # (Required) Path to a JAR file run during the step.     
      args       = optional(list(string)) # (Optional) List of command line arguments passed to the JAR file's main function when executed.
      main_class = optional(string)       # (Optional) Name of the main class in the specified Java file. If not specified, the JAR file should specify a Main-Class in its manifest file.
      properties = optional(string)       # (Optional) Key-Value map of Java properties that are set when the step runs. You can use these properties to pass key value pairs to your main function.
    })
  }))
  default = null
}

variable "step_concurrency_level" {
  description = "(Optional) Number of steps that can be executed concurrently. You can specify a maximum of 256 steps. Only valid for EMR clusters with release_label 5.28.0 or greater (default is 1)."
  type        = number
  default     = null
}

variable "tags" {
  description = "(Optional) list of tags to apply to the EMR Cluster."
  type        = map(string)
  default     = null
}

variable "termination_protection" {
  description = "(Optional) Switch on/off termination protection (default is false, except when using multiple master nodes). Before attempting to destroy the resource when termination protection is enabled, this configuration must be applied with its value set to false."
  type        = bool
  default     = null
}

variable "visible_to_all_users" {
  description = "(Optional) Whether the job flow is visible to all IAM users of the AWS account associated with the job flow. Default value is true."
  type        = bool
  default     = null
}
