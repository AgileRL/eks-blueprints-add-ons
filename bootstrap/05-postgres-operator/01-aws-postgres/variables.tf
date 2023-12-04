variable "cluster_name" {
  description = "The name of the EKS cluster"
  type = string
}
variable "s3_backup_bucket_name" {
  description = "The name of S3 bucket for backups"
  type        = string
  default     = "backups"
}

