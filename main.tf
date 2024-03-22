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

  instances = flatten([
    for env, details in local.config.envs : [
      for instance_type in details.instance_types : [
        for subnet_id in details.subnets : {
          custom_settings = merge(
            details.custom_settings,
            { use_private_dns = details.custom_settings.use_private_dns }
          )
          instance_type = instance_type
          subnet_id     = subnet_id
          tags = merge(
            {
              Entity       = local.config.additional_settings.custom_tags.entity
              Env          = env
              Environment  = details.custom_settings.additional_tags.environment
              InstanceType = instance_type
              MultiSubnet  = length(details.subnets) > 1
              Owner        = details.custom_settings.additional_tags.owner
              Project      = local.config.additional_settings.custom_tags.project
              Subnet       = subnet_id
            }
          )
        }
      ]
    ]
  ])

  transformed_config = {
    for env in keys(local.config.envs) : env => {
      instances = [for instance in local.instances : instance if instance.tags.Env == env]
      regions   = [local.config.envs[env].region]
    }
  }
}

output "transformed_config" {
  value = local.transformed_config
}
