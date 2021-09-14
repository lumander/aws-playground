[
    {
      "name": "frontend",
      "image": "${repository_url}:${tag}",
      "essential": true,
      "memory": 512,
      "cpu": 256,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "environment": [
        {"name": "BASE_URL", "value": "http://${backend-lb}:9000"}
    ]
    }
  ]
  