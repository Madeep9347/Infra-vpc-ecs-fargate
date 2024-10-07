output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecs_cluster_id" {
  description = "The ID of the ECS Cluster"
  value       = module.ecs.ecs_cluster_id
}

output "auth_service_name" {
  description = "The name of the Auth ECS service"
  value       = module.ecs.auth_service_name
}

output "environxchange_service_name" {
  description = "The name of the Environxchange ECS service"
  value       = module.ecs.environxchange_service_name
}
