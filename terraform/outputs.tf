output "default_vpc_id" {
  description = "Existing default VPC used by the cluster."
  value       = data.aws_vpc.default.id
}

output "default_subnet_ids" {
  description = "Existing default subnets."
  value       = sort(data.aws_subnets.default.ids)
}

output "control_plane_public_ip" {
  description = "Control-plane address for SSH and Kubernetes API access."
  value       = aws_instance.control_plane.public_ip
}

output "worker_public_ip" {
  description = "Worker address for SSH access."
  value       = aws_instance.worker.public_ip
}
