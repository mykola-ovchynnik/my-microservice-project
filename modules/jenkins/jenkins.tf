resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.0.16"
  create_namespace = false

  timeout = 1200
  wait    = true

  values = [
    templatefile("${path.module}/values.yaml", {
      ECR_REPOSITORY_URL = var.ecr_repository_url
    })
  ]

  set {
    name  = "controller.admin.username"
    value = var.jenkins_admin_user
  }

  set {
    name  = "controller.admin.password"
    value = var.jenkins_admin_password
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  depends_on = [
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role_binding.jenkins
  ]
}

resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins-admin"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_ecr_role.arn
    }
  }

  depends_on = [kubernetes_namespace.jenkins]
}

resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}
