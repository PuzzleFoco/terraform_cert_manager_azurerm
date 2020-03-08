provider "helm" {
    version        = "~> 1.0.0"

    kubernetes {
      host                   = module.k8s.host
      client_certificate     = base64decode(module.k8s.client_certificate)
      client_key             = base64decode(module.k8s.client_key)
      cluster_ca_certificate = base64decode(module.k8s.cluster_ca_certificate)
      load_config_file       = false
  }
}

module "nginx" {
    source = "../../terraform_nginx_helm"

}