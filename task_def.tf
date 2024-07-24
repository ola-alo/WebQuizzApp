# Create task_definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-first-task" # Name your task

  provisioner "local-exec" {
    command     = "bash ${var.script_name} ${aws_ecr_repository.app_ecr_repo.repository_url}"
    working_dir = path.module
  }
  
  container_definitions    = <<DEFINITION
  [
    {
      "name": "app-first-task",
      "image": "${aws_ecr_repository.app_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  depends_on = [aws_ecr_repository.app_ecr_repo]
}
