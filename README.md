# Varnam – Cloud-Native Bookstore Deployment on AWS
![Varnam](images/1.png)
![Varnam](images/2.png)
![Varnam](images/3.png)

## Overview

Varnam is a web-based bookstore application built to demonstrate containerization and deployment of a multi-tier application on AWS.

The application uses a React frontend and FastAPI backend, packaged as separate Docker images and stored in Amazon Elastic Container Registry (ECR). The images are pulled onto EC2 instances for deployment.

Infrastructure is provisioned using Terraform.

## Technology Stack

| Component | Technology |
|---|---|
| Frontend | React, Vite |
| Backend | Python, FastAPI |
| Database | PostgreSQL |
| Containerization | Docker |
| Container Registry | Amazon ECR |
| Compute | Amazon EC2 |
| Load Balancing | Application Load Balancer |
| Auto Scaling | EC2 Auto Scaling Group |
| Database Hosting | Amazon RDS |
| Infrastructure as Code | Terraform |
| Region | ap-southeast-2 (Sydney) |

## Architecture

```text
                  Internet
                     |
                     v
          Application Load Balancer
                     |
                     v
              EC2 Instances
                     |
          +----------+----------+
          |                     |
          v                     v
    Frontend Container    Backend Container
       (Nginx)              (FastAPI)
          |                     |
          +----------+----------+
                     |
                     v
               PostgreSQL
                 (RDS)
```

Docker images are maintained separately for the frontend and backend.

## Project Structure

```text
varnam/
│
├── frontend/
│   ├── src/
│   ├── public/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── package-lock.json
│
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
│
└── infrastructure/
    └── main.tf
```

## Application Containerization

The frontend and backend are packaged as independent Docker images.

### Frontend

- Uses Node.js to build the React application.
- Uses Nginx as the production web server.
- Serves static frontend assets.
- Proxies API requests to the backend service.

### Backend

- Built using FastAPI.
- Runs using Uvicorn.
- Exposes application and health-check endpoints.
- Designed to communicate with PostgreSQL.

## AWS Infrastructure

The infrastructure is provisioned using Terraform.

Key components:

- VPC with public and private subnets.
- Internet Gateway and public routing.
- Application Load Balancer.
- EC2 instances managed through an Auto Scaling Group.
- Security groups controlling application and database access.
- Amazon RDS for PostgreSQL.
- Amazon ECR repositories for application images.
- IAM roles for EC2 access to AWS services.

## Container Image Deployment

Application images are stored in Amazon ECR.

Deployment workflow:

1. Build frontend and backend Docker images.
2. Authenticate Docker with Amazon ECR.
3. Tag the images with their respective ECR repository URIs.
4. Push the images to ECR.
5. Pull the images onto EC2 instances.
6. Run the application containers.

### ECR Authentication

```bash
aws ecr get-login-password --region ap-southeast-2 | \
docker login --username AWS --password-stdin \
<ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com
```

### Push Images

```bash
docker tag varnam-frontend:local \
<ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com/varnam-frontend:latest

docker tag varnam-backend:local \
<ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com/varnam-backend:latest
```

```bash
docker push <ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com/varnam-frontend:latest

docker push <ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com/varnam-backend:latest
```

### Pull Images on EC2

Authenticate the EC2 instance using its IAM role, then pull:

```bash
docker pull <ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com/varnam-frontend:latest

docker pull <ACCOUNT_ID>.dkr.ecr.ap-southeast-2.amazonaws.com/varnam-backend:latest
```

## Security Considerations

- Use IAM roles instead of hardcoded AWS access keys.
- Restrict application instance access through security groups.
- Allow database connections only from the application security group.
- Keep RDS instances private.
- Avoid storing database credentials in source code.
- Use encrypted storage for database resources.
- Expose the application through the ALB rather than directly exposing application containers.

## Monitoring and Operations

Operational monitoring can be implemented using Amazon CloudWatch.

Recommended metrics:

- EC2 CPU utilization.
- ALB request count and HTTP 5xx errors.
- Healthy target count.
- RDS CPU utilization.
- RDS free storage space.

## Project Objectives

- Provision AWS infrastructure using Terraform.
- Containerize a multi-tier application.
- Maintain separate frontend and backend images.
- Use ECR as a centralized container registry.
- Deploy containerized workloads onto EC2.
- Implement secure network communication between application tiers.
- Build a scalable and maintainable AWS deployment architecture.

---

**Project:** Varnam  
**Cloud Provider:** AWS  
**Infrastructure as Code:** Terraform  
**Application Deployment:** Docker and Amazon ECR