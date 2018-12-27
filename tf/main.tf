module "gke" {
  source             = "git::https://github.com/lsst-sqre/terraform-gke-std.git//?ref=master"
  name               = "${local.gke_cluster_name}"
  google_project     = "${var.google_project}"
  gke_version        = "latest"
  initial_node_count = 3
  machine_type       = "n1-standard-1"
}

provider "kubernetes" {
  version = "~> 1.4"

  load_config_file = true

  host                   = "${module.gke.host}"
  cluster_ca_certificate = "${base64decode(module.gke.cluster_ca_certificate)}"
}

provider "aws" {
  version = "~> 1.21"
  region  = "${var.aws_primary_region}"
  alias   = "primary"
}

provider "aws" {
  # providers are initialized early and can't use a local var to DRY version
  version = "~> 1.21"
  region  = "${var.aws_backup_region}"
  alias   = "backup"
}

module "tiller" {
  source          = "git::https://github.com/lsst-sqre/terraform-tinfoil-tiller.git//?ref=master"
  namespace       = "kube-system"
  service_account = "tiller"
}

provider "helm" {
  version = "~> 0.6.2"

  service_account = "${module.tiller.service_account}"
  namespace       = "${module.tiller.namespace}"
  install_tiller  = false

  kubernetes {
    host                   = "${module.gke.host}"
    cluster_ca_certificate = "${base64decode(module.gke.cluster_ca_certificate)}"
  }
}
