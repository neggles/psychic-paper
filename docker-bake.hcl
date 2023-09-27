# docker-bake.hcl for stable-diffusion-webui
group "default" {
  targets = ["gradient-torch201"]
}

group torchrc {
  targets = ["gradient-torch210"]
}

variable IMAGE_REGISTRY {
  default = "ghcr.io"
}

variable IMAGE_NAMESPACE {
  default = "neggles/psychic-paper"
}

variable CUDA_VERSION {
  default = "12.1.1"
}

variable TORCH_CUDA_ARCH_LIST {
  default = "7.0;7.5;8.0;8.6;8.9;9.0"
}

# removes characters not valid in a target name, useful for other things too
function stripName {
  params = [name]
  result = regex_replace(name, "[^a-zA-Z0-9_-]+", "")
}

# convert a CUDA version number and container dev type etc. into an image URI
function cudaImage {
  params          = [cudaVer, cudaType]
  variadic_params = extraVals
  result = join(":", [
    "nvidia/cuda",
    join("-", [cudaVer], extraVals, [cudaType, "ubuntu22.04"])
  ])
}

# convert a CUDA version number into a release number (e.g. 11.2.1 -> 11-2)
function cudaRelease {
  params = [version]
  result = regex_replace(version, "^(\\d+)\\.(\\d).*", "$1-$2")
}

# build a tag for an image from this repo
function repoImage {
  params          = [imageName]
  variadic_params = extraVals
  result = join(":", [
    join("/", [IMAGE_REGISTRY, IMAGE_NAMESPACE, imageName]),
    join("-", extraVals)
  ])
}

# set to "true" by github actions, used to disable auto-tag
variable CI { default = "" }

# docker-metadata-action will populate this in GitHub Actions
target docker-metadata-action {}

# Shared amongst all containers
target common {
  context = "./docker"
  args = {
    CUDA_VERSION = CUDA_VERSION
    CUDA_RELEASE = cudaRelease(CUDA_VERSION)

    TORCH_CUDA_ARCH_LIST = TORCH_CUDA_ARCH_LIST
  }
  platforms = ["linux/amd64"]
}

# Base image with cuda, python, torch, and other dependencies
target base-torch201 {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.base"
  target     = "base-xformers-bin"
  args = {
    TORCH_INDEX    = "https://download.pytorch.org/whl/cu118"
    TORCH_PACKAGE  = "torch"
    EXTRA_PIP_ARGS = ""

    XFORMERS_PACKAGE = "xformers==0.0.21"
  }
}

target base-torch210 {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.base"
  target     = "base-xformers-ghcr"
  args = {
    TORCH_INDEX    = "https://download.pytorch.org/whl/test/cu121"
    TORCH_PACKAGE  = "torch"
    EXTRA_PIP_ARGS = ""

    XFORMERS_OCI_IMAGE = "ghcr.io/neggles/tensorpods/xformers:v0.0.21-cu121-torch210"
  }
}

# Paperspace Gradient image
target gradient-torch201 {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.gradient"
  target     = "gradient"
  contexts = {
    base = "target:base-torch201"
  }
  args = {
    NODE_MAJOR = 18
  }
}

target gradient-torch210 {
  inherits   = ["common", "docker-metadata-action"]
  dockerfile = "Dockerfile.gradient"
  target     = "gradient"
  contexts = {
    base = "target:base-torch210"
  }
  args = {
    NODE_MAJOR = 18
  }
}
