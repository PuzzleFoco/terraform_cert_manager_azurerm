# ---------------------------------------------------------------------------------------------------------------------
# Cert-Manager
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    helm = ">= 1.0.0"
  }
}

// Describes the version of CustomResourceDefinition and Cert-Manager Helmchart
locals {
  customResourceDefinition = "v0.15.0"
  certManagerHelmVersion   = "v0.15.0"
}

// ensures that the right kubeconfig is used local
resource "null_resource" "get_kubectl" {
  provisioner "local-exec" {
    command = "az aks get-credentials -n ${var.cluster_name} -g ${var.resource_group_name} --overwrite-existing"
  }
}

// Install the CustomResourceDefinition resources separately (requiered for Cert-Manager) 
resource "null_resource" "install_crds" {
  provisioner "local-exec" {
    when    = create
    command = "kubectl --context ${var.cluster_name} apply -f https://github.com/jetstack/cert-manager/releases/download/${local.customResourceDefinition}/cert-manager.crds.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --context ${var.cluster_name} delete -f https://github.com/jetstack/cert-manager/releases/download/${local.customResourceDefinition}/cert-manager.crds.yaml"
  }
  depends_on = [null_resource.get_kubectl]
}

// Creates Namespace for cert-manager. necessary to disable resource validation
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on  = [null_resource.install_crds]
}

// Adds jetsteck to helm repo
data "helm_repository" "jetstack" {
  name     = "jetstack"
  url      = "https://charts.jetstack.io"
}

// Install cert-manager via helm in namespace cert-manager
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = data.helm_repository.jetstack.name
  chart      = "cert-manager"
  version    = local.certManagerHelmVersion
}

// Creates secret with our client_secret inside. Is used to give cert-manager the permission to make an  acme-challenge to prove let's encrypt
// that we are the owner of our domain
resource "kubernetes_secret" "cert-manager-secret" {
  metadata {
    name      = "secret-azure-config"
    namespace = kubernetes_namespace.cert_manager.metadata.0.name
  }
  data = {
    password = "${var.client_secret}"
  }
}

// Creates a template file with all necessary variables for permission. This template contains a clusterissuer and a certificate
data "template_file" "cert_manager_manifest" {
  template = "${file("${path.module}/cert-manager.yaml")}"

  vars = {
    AZURE_SERVICE_PRINCIPAL_ID = "${var.client_id}"
    DOMAIN                     = "${var.root_domain}"
    NAMESPACE                  = "${kubernetes_namespace.cert_manager.metadata.0.name}"
    AZURE_SUBSCRIPTION_ID      = "${var.subscription_id}"
    AZURE_TENANT_ID            = "${var.tenant_id}"
    AZURE_RESOURCE_GROUP       = "${var.dns_zone_resource_group}"
    AZURE_DNS_ZONE_NAME        = "${var.root_domain}"
    CERT_NAME                  = "wildcard"
    PASSWORD                   = "password"
    SECRET_NAME                = "${kubernetes_secret.cert-manager-secret.metadata.0.name}"
    EMAIL                      = "${var.lets_encrypt_email}"
  }
}

// Install our cert-manager template
resource "null_resource" "install_k8s_resources" {
  provisioner "local-exec" {
    when    = create
    command = "kubectl --context ${var.cluster_name} apply -f -<<EOL\n${data.template_file.cert_manager_manifest.rendered}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --context ${var.cluster_name} delete -f -<<EOL\n${data.template_file.cert_manager_manifest.rendered}\nEOL"
  }
  depends_on = [null_resource.install_crds]
}