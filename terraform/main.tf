provider "honeycombio" {
  # expecting HONEYCOMB_API_KEY and HONEYCOMB_API_ENDPOINT to be set as environment variables
}

terraform {
  required_providers {
    honeycombio = {
      source  = "honeycombio/honeycombio"
      version = "~> 0.23.0"
    }
  }

  backend "kubernetes" {
    secret_suffix = "state"
    config_path   = "~/.kubeconfig"
    # namespace is set via the KUBE_NAMESPACE environment variable
  }
}
