locals {
  config = {
    envs = {
      dev = {
        region         = "us-west-2"
        instance_types = ["t2.micro", "t2.small"]
        subnets        = ["subnet-12345678", "subnet-87654321"]
        custom_settings = {
          use_private_dns = true
          additional_tags = {
            environment = "development"
            owner       = "dev_team"
          }
        }
      },
      prod = {
        region         = "us-east-1"
        instance_types = ["t3.medium", "t3.large"]
        subnets        = ["subnet-98765432", "subnet-56789012"]
        custom_settings = {
          use_private_dns = false
          additional_tags = {
            environment = "production"
            owner       = "prod_team"
          }
        }
      }
    },
    additional_settings = {
      monitoring_enabled = true
      custom_tags = {
        project = "example_project"
        entity  = "foo_bar"
      }
    }
  }

  transformed_config = {
    for env, env_config in local.config.envs : env => {
      instances = flatten([
        for instance_type in env_config.instance_types : [
          for subnet in env_config.subnets : {
            custom_settings = env_config.custom_settings
            instance_type   = instance_type
            subnet_id       = subnet
            tags = merge(
              local.config.additional_settings.custom_tags,
              env_config.custom_settings.additional_tags,
              {
                "Env"          = env
                "Environment"  = env_config.custom_settings.additional_tags.environment
                "InstanceType" = instance_type
                "MultiSubnet"  = length(env_config.subnets) > 1
                "Owner"        = env_config.custom_settings.additional_tags.owner
                "Project"      = local.config.additional_settings.custom_tags.project
                "Subnet"       = subnet
              }
            )
          }
        ]
      ])
      regions = [env_config.region]
    }
  }
}

output "transformed_config" {
  value = local.transformed_config
}

