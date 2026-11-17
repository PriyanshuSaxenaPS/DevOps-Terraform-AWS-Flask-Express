# Terraform AWS DevOps Assignment (Flask + Express)

This repository contains the practical assignment for the **TuteDude DevOps** module, utilizing **Terraform** to provision a full-stack **Python/Flask** backend and **Node.js/Express** frontend across three progressive AWS architectures in **`ap-south-1` (Mumbai)**.

---

## 📌 Deployment Architectures Implemented

1. **Part 1 — Single EC2 Instance (`part1-single-ec2/`)**: Deploys Flask (`TCP 5000`) and Express (`TCP 3000`) on a single Ubuntu EC2 instance via `user_data.sh` and `systemd`.
2. **Part 2 — Separate EC2 Instances (`part2-two-ec2/`)**: Decouples frontend and backend onto dedicated EC2 instances (`frontend_user_data.sh` and `backend_user_data.sh`) communicating over private IPv4.
3. **Part 3 — Docker, ECR, ECS Fargate & ALB (`part3-ecs-ecr-alb/`)**: Provisions a custom VPC, Amazon ECR repositories, ECS Fargate cluster/services, CloudWatch log groups, and an Application Load Balancer backed by an encrypted S3 remote state bucket.

---

## 🛠️ Tech Stack & AWS Services
* **Infrastructure as Code:** Terraform (`>= 1.5`)
* **Backend / Frontend:** Python/Flask (`apps/flask`), Node.js/Express.js (`apps/express`)
* **Containerization & Automation:** Docker, Bash scripts (`scripts/`)
* **AWS Services:** EC2, VPC, Subnets, Security Groups, IAM, S3, ECR, ECS Fargate, ALB, CloudWatch

---

## 📂 Complete Repository Structure

terraform-aws-flask-express/
├── apps/
│   ├── express/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   └── flask/
│       ├── Dockerfile
│       ├── app.py
│       └── requirements.txt
├── part1-single-ec2/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── user_data.sh
│   └── variables.tf
├── part2-two-ec2/
│   ├── backend_user_data.sh
│   ├── frontend_user_data.sh
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── variables.tf
├── part3-ecs-ecr-alb/
│   ├── backend.hcl.example
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── variables.tf
├── scripts/
│   ├── part3-build-push.sh
│   └── verify.sh
├── state-bootstrap/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── variables.tf
├── .gitignore
├── Assignment_8_Terraform.docx
├── GITHUB_REPOSITORY.txt
└── README.md

---

## ⚙️ Prerequisites & One-Time Setup

* **Prerequisites:** AWS account with permissions for EC2, VPC, IAM, S3, ECR, ECS, ELB, and CloudWatch; AWS CLI v2 configured; Terraform `>= 1.5`, Docker, and Git installed.
* **Step 1: Bootstrap S3 Remote State (`state-bootstrap/`)**:
  cd state-bootstrap
  cp terraform.tfvars.example terraform.tfvars
  # Edit state_bucket to a globally unique name
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply

---

## 🚀 Deployment Instructions

### Part 1 — Single EC2 Instance (`part1-single-ec2/`)
  cd part1-single-ec2
  cp terraform.tfvars.example terraform.tfvars
  # Edit ssh_cidr to YOUR_PUBLIC_IP/32
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply
  terraform output
* **Verification:** Wait 3–5 minutes for cloud-init. Access Express at `http://<PUBLIC_IP>:3000/` and Flask at `http://<PUBLIC_IP>:5000/api/hello`.
* **Teardown:** `terraform destroy`

### Part 2 — Separate EC2 Instances (`part2-two-ec2/`)
  cd part2-two-ec2
  cp terraform.tfvars.example terraform.tfvars
  # Edit ssh_cidr
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply
  terraform output
* **Verification:** Test private inter-service communication and public endpoints.
* **Teardown:** `terraform destroy`

### Part 3 — Docker, ECR, ECS Fargate & ALB (`part3-ecs-ecr-alb/`)
1. **Provision Infrastructure & Configure Backend:**
   cd part3-ecs-ecr-alb
   cp terraform.tfvars.example terraform.tfvars
   cp backend.hcl.example backend.hcl
   # Update backend.hcl with your S3 state bucket name
   terraform init -backend-config=backend.hcl
   terraform fmt -recursive
   terraform validate
   terraform plan
   terraform apply
2. **Build & Push Docker Images to ECR:**
   From the repository root:
   chmod +x scripts/part3-build-push.sh
   AWS_REGION=ap-south-1 ./scripts/part3-build-push.sh
3. **Force ECS Service Deployments:**
   aws ecs update-service --cluster terraform-demo-p3-cluster --service terraform-demo-p3-flask --force-new-deployment --region ap-south-1
   aws ecs update-service --cluster terraform-demo-p3-cluster --service terraform-demo-p3-express --force-new-deployment --region ap-south-1
4. **Verification:** Open the ALB DNS output URL (`/` routes to Express, `/api/hello` routes to Flask).

---

## 🧹 Teardown & Cost Management
To avoid ongoing AWS charges, run `terraform destroy` sequentially within `part3-ecs-ecr-alb/` and `state-bootstrap/` once testing is complete.

---

## 🔒 Security Notes
* Never commit `.tfstate`, `.terraform/`, AWS credentials, or populated `.tfvars` / `backend.hcl` files.
* Restrict SSH access in Parts 1 and 2 using specific `ssh_cidr` blocks (`YOUR_PUBLIC_IP/32`).
