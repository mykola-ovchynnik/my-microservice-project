resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "django_app" {
  metadata {
    name = "django-app"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  timeout = 900
  wait    = true

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [kubernetes_namespace.argocd]
}

resource "helm_release" "argocd_applications" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  timeout = 300
  wait    = true

  set {
    name  = "gitRepoUrl"
    value = var.git_repo_url
  }

  set {
    name  = "targetRevision"
    value = var.git_target_revision
  }

  set {
    name  = "djangoAppNamespace"
    value = var.django_app_namespace
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_namespace.django_app
  ]
}
