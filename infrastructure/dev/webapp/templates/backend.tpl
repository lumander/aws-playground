[
    {
      "name": "backend",
      "image": "${repository_url}:${tag}",
      "essential": true,
      "memory": 512,
      "cpu": 256,
      "portMappings": [
        {
          "containerPort": 9000,
          "hostPort": 9000
        }
      ]
    }
  ]
