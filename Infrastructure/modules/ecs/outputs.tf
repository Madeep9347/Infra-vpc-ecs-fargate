output "ecs_cluster_id" {
  description = "The ID of the ECS Cluster"
  value       = aws_ecs_cluster.fargate_cluster.id
}

output "auth_service_name" {
  description = "The name of the Auth ECS service"
  value       = aws_ecs_service.auth_service.name
}

output "environxchange_service_name" {
  description = "The name of the Environxchange ECS service"
  value       = aws_ecs_service.environxchange_service.name
}
