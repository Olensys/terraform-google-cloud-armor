terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Upstream 9.0.0 requires google >= 7.17, so the floor is raised above the library default.
    google = {
      source  = "hashicorp/google"
      version = ">= 7.17, < 8.0"
    }
    # Upstream creates the security policy through google-beta.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.17, < 8.0"
    }
  }
}
