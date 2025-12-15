locals {
  bastion_hosts = {
    # First bastion host - primary jump box for accessing private resources
    bastion_host_1 = {
        name = "bastion-host"                     # Display name for EC2 instance (used in AWS console tags)
        ami  = "ami-0030e4319cbf4dbf2"            # Ubuntu AMI ID for us-east-1 region (must be region-specific)
        ami-owner = "099720109477"                # Canonical's AWS account ID (official Ubuntu publisher)
        instance-type = "t3a.nano"                # EC2 size: 2 vCPU, 0.5GB RAM (~$3.50/month on-demand)
        root-volume-size = 10                     # Boot disk size in GB (OS storage)
        vpc-id = data.terraform_remote_state.network.outputs.dev-sd5046-aws-infrastructure-vpc.id  # VPC to launch instance in
        security-group-ids = data.terraform_remote_state.network.outputs.security-groups.bastion-host  # Firewall rules (SSH access)
        ebs-volume-count = 0                      # Number of additional data disks (0 = no extra volumes)
        ebs-volume-size = 20                      # Size of each additional EBS volume (only if ebs-volume-count > 0)
        create-default-security-group = true      # Auto-create security group vs using existing one
        generate-ssh-key-pair = true              # Auto-generate new SSH key pair for access
        ssh-key-pair-path = "./"                  # Directory to save generated private key file
        associate_public_ip_address = true        # Assign public IP for internet access (required for bastion)
        subnet_id = data.terraform_remote_state.network.outputs.dev-public-subnet-0.id  # Public subnet in AZ 1
        availability-zone = data.terraform_remote_state.network.outputs.dev-public-subnet-0.availability_zone  # e.g., us-east-1a
        instance-count = 1                        # Number of instances to create (1 = single bastion)
        iam-role-default-name = data.terraform_remote_state.bootstrap.outputs.bastion_role_name  # IAM role for AWS permissions
        iam-instance-profile-name = "bastion-host-1-profile"  # Instance profile wrapper for IAM role
        ebs-volume-name = "volume of the Bastion host"  # Tag name for additional EBS volumes
    }

    # Second bastion host - provides high availability in different AZ
    bastion_host_2 = {
        name = "bastion-host-2"                   # Display name for second bastion
        ami  = "ami-0030e4319cbf4dbf2"            # Same Ubuntu AMI as bastion_host_1
        ami-owner = "099720109477"                # Canonical (Ubuntu publisher)
        instance-type = "t3a.nano"                # Same instance size as primary bastion
        root-volume-size = 10                     # Boot disk size
        vpc-id = data.terraform_remote_state.network.outputs.dev-sd5046-aws-infrastructure-vpc.id  # Same VPC
        security-group-ids = data.terraform_remote_state.network.outputs.security-groups.bastion-host  # Same security group
        ebs-volume-count = 0                      # No additional data disks
        ebs-volume-size = 20                      # Size if additional volumes were added
        associate_public_ip_address = true        # Public IP for internet access
        create-default-security-group = true      # Auto-create security group
        generate-ssh-key-pair = true              # Auto-generate SSH key
        ssh-key-pair-path = "./"                  # Save key to current directory
        subnet_id = data.terraform_remote_state.network.outputs.dev-public-subnet-1.id  # Public subnet in AZ 2 (different from bastion_host_1)
        availability-zone = data.terraform_remote_state.network.outputs.dev-public-subnet-1.availability_zone  # e.g., us-east-1b
        instance-count = 1                        # Create 1 instance (set to 0 to disable for cost savings)
        iam-role-default-name = "bastion-sd5046-aws-infrastructure-0002"  # Different IAM role name than bastion_host_1
        iam-instance-profile-name = "bastion-host-2-profile"  # Unique instance profile
        ebs-volume-name = "volume of the Bastion host"  # Tag for additional volumes
    }
  }
}   