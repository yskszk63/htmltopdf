terraform {
  required_version = ">=1.2.9"
  required_providers {
    aws = "~>4.31.0"
    null = "~>3.1.1"
    archive = "~>2.2.0"
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project = "htmltopdf"
    }
  }
}
