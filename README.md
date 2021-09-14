# aws-playground     <img align="right" src="/docs/awsLogo.jpeg" width="10%">

Managed with Terraform. The code deploys a web application in High Availability, among eu-west-1a, eu-west-1b and eu-west-1c. 

For the deployment procedure, please follow the guide [here](/docs/deployment-guide.md).


## High Level Architecture

![HLA](/docs/HLA.png)

## Description

The infrastructure deployment will create a dedicated vpc organized in three subnets spanning three availability zones.
One is public, the others are private ( webapp fe and be and dbs ) and routing traffic to a NAT Gateway.
All the services will be distributed among the three availability zones.
Then the ECS and ECR are then deployed. The RDS cluster instance is deployed in the private db subnets.
Last step is the deployment of the webapp infrastructure and Fargate services.
Both the frontend and the backend resides in the private subnet. The frontend is reachable via an Application Load Balancer.
Each request to the frontend is proxied to the internal Application Load Balancer for the backend by NGINX.
The static content on the page ( AWS Logo ), is then served by the CloudFront distribution.

### AWS Services
- S3
- DynamoDB (only for Terraform state file locks)
- VPC
- Security Groups
- NAT Gateway
- Internet Gateway
- ECS
- ECR
- Fargate
- RDS
- ALB
- CloudFront
