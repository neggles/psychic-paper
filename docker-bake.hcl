# docker-bake.hcl for stable-diffusion-webui
group "default" {
  targets = ["gradient"]
}

variable "IMAGE_REGISTRY" {
  default = "ghcr.io"
}

variable "IMAGE_NAME" {
  default = "neggles/psychic-paper"
}

variable "BASE_IMAGE" {
  default = "nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04"
}

variable "CUDA_VERSION" {
  default = "12.1"
}

variable "TORCH_VERSION" {
  default = "torch"
}

variable "TORCH_INDEX" {
  default = "https://download.pytorch.org/whl/cu118"
}

variable "TORCH_CUDA_ARCH_LIST" {
  default = "7.0;7.5;8.0;8.6;8.9;9.0"
}

variable "XFORMERS_VERSION" {
  default = "xformers==0.0.21"
}

# docker-metadata-action will populate this in GitHub Actions
target "docker-metadata-action" {}

# Shared amongst all containers
target "common" {
  context = "./docker"
  args = {
    CUDA_VERSION = CUDA_VERSION
    CUDA_RELEASE = "${regex_replace(CUDA_VERSION, "\\.", "-")}"

    TORCH_CUDA_ARCH_LIST = TORCH_CUDA_ARCH_LIST
  }
  platforms = ["linux/amd64"]
}

# Base image with cuda, python, torch, and other dependencies
target "base" {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.base"
  target     = "base"
  args = {
    TORCH_INDEX    = TORCH_INDEX
    TORCH_VERSION  = TORCH_VERSION
    EXTRA_PIP_ARGS = ""

    XFORMERS_VERSION = XFORMERS_VERSION
  }
}

# Paperspace Gradient image
target "gradient" {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.gradient"
  target     = "gradient"
  contexts = {
    base = "target:base"
  }
  args = {
    NODE_MAJOR = 18
  }
}
