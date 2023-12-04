variable "cluster_name" {
  description = "The name of the EKS cluster"
  type = string
}
variable "bucket_name" {
  description = "The name of S3 bucket for backups"
  type        = string
  default     = "backups"
}
variable "tags" {
  description = "Tags to set on the bucket."
  type        = map(string)
  default     = {}
}
