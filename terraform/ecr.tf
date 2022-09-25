resource "aws_ecr_repository" "ecr" {
  name = "htmltopdf"
  force_delete = true
}

data "aws_ecr_authorization_token" "token" {
}

resource "null_resource" "dummy_image" {
  provisioner "local-exec" {
    command = "echo ${data.aws_ecr_authorization_token.token.password} | docker login --username AWS --password-stdin ${aws_ecr_repository.ecr.repository_url}"
  }

  provisioner "local-exec" {
    command = "docker pull busybox:latest"
  }

  provisioner "local-exec" {
    command = "docker tag busybox:latest ${aws_ecr_repository.ecr.repository_url}:latest"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.ecr.repository_url}:latest"
  }
}
