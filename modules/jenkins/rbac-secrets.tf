resource "kubernetes_role" "jenkins_secrets_reader" {
  metadata {
    name      = "jenkins-secrets-reader"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "jenkins_secrets_reader" {
  metadata {
    name      = "jenkins-secrets-reader"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.jenkins_secrets_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}
