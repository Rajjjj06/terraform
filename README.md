# Flask and Express AWS Deployments with Terraform

## Project repository

The complete source code and latest project files are available on GitHub:

<https://github.com/Rajjjj06/terraform>

The compressed submission may contain only the required Terraform files because
Terraform provider binaries and generated state files can make the archive
larger than the submission limit. These generated files are intentionally
excluded from the repository and can be recreated with `terraform init`.

This project demonstrates three ways to deploy the same Flask backend and Express frontend on AWS:

1. Both applications on one EC2 instance.
2. The applications on two separate EC2 instances.
3. Containerized applications on ECS Fargate behind an Application Load Balancer (ALB).

The applications use these ports:

| Application | Port | Important endpoints |
|---|---:|---|
| Flask backend | `5000` | `GET /health`, `POST /submit`, `GET /data` |
| Express frontend | `3000` | `GET /`, `POST /submit` |

The screenshots in the project show the frontend form, successful submission page, and backend JSON responses.

> **Submission note:** The GitHub repository is the authoritative copy of the
> project. Large Terraform provider downloads, Terraform state files, and
> environment-specific variable files are not included in the compressed
> submission.

## Repository layout

```text
part-1/                   One EC2 instance deployment
part-2/                   Two EC2 instance deployment
part-3/                   ECS Fargate, VPC, security groups, service discovery, and ALB
```

This reduced submission contains the Terraform deployment definitions. Each
Terraform part is independent; run Terraform from the selected part directory,
not from the repository root. The application source and Docker build context
can be restored from the linked GitHub repository when needed.

## Prerequisites

- An AWS account with permissions to create the resources described below.
- Terraform `>= 1.5` and the AWS provider configured by the project.
- AWS CLI configured with credentials (`aws configure`, environment variables, or an instance profile).
- A key pair if SSH access is required.
- Docker for the ECS deployment.
- Git repositories or URLs accessible from the EC2 user-data scripts.

> **Important:** AMI IDs are region-specific. The default AMI is configured for `ap-south-2`. Replace it with an Ubuntu AMI valid for your selected region before deploying elsewhere. Also review the repository URLs in the user-data scripts.

## Common Terraform workflow

From the directory for the deployment you want to run:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

When finished, destroy resources to avoid ongoing AWS charges:

```powershell
terraform destroy
```

Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, `tfplan`, or `.tfvars` files containing secrets.

## Part 1: Flask and Express on one EC2 instance

### Objective

Provision one EC2 instance and run Flask on port `5000` and Express on port `3000`.

### Terraform files

- `part-1/main.tf` creates the EC2 instance and security group.
- `part-1/variables.tf` defines the AWS region, AMI, instance type, project name, and application ports.
- `part-1/outputs.tf` prints the instance IP and application URLs.
- `part-1/user_data.sh` installs Git, Python, pip, Python virtual environments, Node.js, and npm, then starts both applications.

The security group allows inbound TCP traffic on ports `3000` and `5000`, and allows outbound traffic. For production, restrict inbound traffic to trusted CIDR ranges or place the services behind an ALB.

### Deploy

```powershell
cd part-1
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Open the output URLs:

```text
http://<public-ip>:3000       Express form
http://<public-ip>:5000/health
http://<public-ip>:5000/data
```

The user-data script writes application output to `/var/log/frontend.log` and `/var/log/backend.log`. If the instance is not ready immediately, wait for cloud-init to finish and inspect `/var/log/cloud-init-output.log` over SSH.

## Part 2: Flask and Express on separate EC2 instances

### Objective

Provision a VPC with public subnets and two EC2 instances:

- The backend instance runs Flask on port `5000`.
- The frontend instance runs Express on port `3000` and receives the backend public IP through `BACKEND_URL`.

### Terraform files

- `part-2/main.tf` creates the VPC, public subnets, internet gateway, route table, security groups, and both instances.
- `part-2/backend.sh` installs Python dependencies and starts Flask.
- `part-2/frontend.sh` installs Node.js dependencies and starts Express with the backend URL.
- `part-2/variables.tf` defines the region, AMI, instance type, names, and ports.
- `part-2/outputs.tf` prints both public IPs and URLs.

The frontend user-data template references `aws_instance.backend_instance.public_ip`, so Terraform creates the backend instance before rendering the frontend configuration. The backend security group currently permits port `5000` from the internet; restrict this to the frontend security group for a production deployment.

### Deploy

```powershell
cd part-2
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Test the applications:

```text
http://<frontend-public-ip>:3000
http://<backend-public-ip>:5000/health
http://<backend-public-ip>:5000/data
```

To confirm frontend-to-backend communication, submit the form at the frontend URL and then request `/data` from the backend URL.

## Part 3: Docker images on ECR and ECS Fargate

### Objective

Run the Flask and Express Docker containers as separate ECS Fargate services in a VPC. The ALB exposes:

- Frontend at port `80`.
- Backend at port `5000`.

The frontend reaches the backend through AWS Cloud Map service discovery using the private DNS name configured in `part-3/service_discovery.tf`.

### Terraform files

- `part-3/networking.tf` creates the VPC, two public subnets, internet gateway, and route table.
- `part-3/security_groups.tf` creates ALB, frontend-task, and backend-task security groups.
- `part-3/ecs.tf` creates the ECS cluster, IAM execution role, CloudWatch log groups, task definitions, and Fargate services.
- `part-3/alb.tf` creates the ALB, target groups, health checks, and listeners.
- `part-3/service_discovery.tf` creates private service discovery for the backend.
- `part-3/variables.tf` accepts the ECR image URIs and task sizing.
- `part-3/outputs.tf` prints the ALB DNS name and URLs.

### Build and push images to ECR

The current `part-3` Terraform configuration expects ECR repositories and image URIs to exist before `terraform apply`. Create the repositories once:

```powershell
$AWS_REGION = "ap-south-2"
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)

aws ecr create-repository --repository-name flask-backend --region $AWS_REGION
aws ecr create-repository --repository-name express-frontend --region $AWS_REGION

aws ecr get-login-password --region $AWS_REGION |
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

Build, tag, and push the images from the repository root:

```powershell
$REGISTRY = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker build -t flask-backend .\backend
docker tag flask-backend "$REGISTRY/flask-backend:latest"
docker push "$REGISTRY/flask-backend:latest"

docker build -t express-frontend .\frontend
docker tag express-frontend "$REGISTRY/express-frontend:latest"
docker push "$REGISTRY/express-frontend:latest"
```

The frontend image must listen on port `3000`. The backend image must listen on port `5000` and provide `GET /health`, which is used by the ALB target-group health check.

### Configure and deploy ECS

Create a local `part-3/terraform.tfvars` file with the image URIs. Do not commit it if it contains private registry details or credentials:

```hcl
aws_region     = "ap-south-2"
frontend_image = "123456789012.dkr.ecr.ap-south-2.amazonaws.com/express-frontend:latest"
backend_image  = "123456789012.dkr.ecr.ap-south-2.amazonaws.com/flask-backend:latest"
```

Deploy:

```powershell
cd part-3
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
terraform output
```

Open the returned `frontend_url`. The backend is also available through the ALB backend listener at:

```text
http://<alb-dns-name>:5000/health
```

View container logs in CloudWatch under:

```text
/ecs/flask-express-ecs/frontend
/ecs/flask-express-ecs/backend
```

## Terraform state management

For team or production use, store state remotely in an encrypted S3 bucket with DynamoDB locking. Bootstrap the state bucket separately because Terraform cannot use an S3 backend before the bucket exists.

Example backend configuration to add to each part after creating the bucket:

```hcl
terraform {
  backend "s3" {
    bucket         = "replace-with-unique-state-bucket"
    key            = "flask-express/part-1/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Use a different `key` for `part-2` and `part-3`. Then migrate local state:

```powershell
terraform init -migrate-state
```

Enable S3 bucket versioning, server-side encryption, public-access blocking, and least-privilege IAM access for the state bucket.

## Validation and troubleshooting

Check Terraform configuration before applying:

```powershell
terraform fmt -check -recursive
terraform validate
terraform plan
```

Useful AWS checks:

```powershell
aws ec2 describe-instances --filters "Name=tag:Name,Values=*" --output table
aws ecs list-services --cluster flask-express-ecs
aws ecs describe-services --cluster flask-express-ecs --services flask-express-ecs-frontend-service flask-express-ecs-backend-service
```

Common issues:

- **No response on a port:** verify the security group, route table, public IP assignment, and that cloud-init completed.
- **Frontend form returns 502:** verify `BACKEND_URL`, backend health, and port `5000` rules.
- **ECS tasks stop:** inspect ECS stopped-task reasons and CloudWatch logs; confirm the task execution role can pull from ECR.
- **ALB targets are unhealthy:** confirm the container listens on `0.0.0.0`, the target port matches Terraform, and `/health` returns HTTP `200`.
- **AMI launch failure:** select an AMI available in the configured AWS region.

## Cleanup

Destroy the selected Terraform deployment:

```powershell
terraform destroy
```

For Part 3, delete ECR repositories separately if they are no longer needed:

```powershell
aws ecr delete-repository --repository-name flask-backend --force --region ap-south-2
aws ecr delete-repository --repository-name express-frontend --force --region ap-south-2
```
