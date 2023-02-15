# Resource: Kubernetes Storage Class
resource "kubernetes_storage_class_v1" "ebs_sc" {  
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = "true"  
  reclaim_policy = "Retain" # Additional Reference: https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/#why-change-reclaim-policy-of-a-persistentvolume
}

# Resource: Persistent Volume Claim
# resource "kubernetes_persistent_volume_claim_v1" "pvc" {
#   metadata {
#     name = "ebs-mysql-pv-claim"
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     storage_class_name = kubernetes_storage_class_v1.ebs_sc.metadata.0.name 
#     resources {
#       requests = {
#         storage = "4Gi"
#         #storage = "6Gi"
#       }
#     }
#   }
# }
