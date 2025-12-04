# APT
This project delivers a one-click, production-style deployment of a simple REST API on AWS using Infrastructure as Code. It provisions a complete network and compute stack, including a load-balanced, auto-scaling application tier running entirely on private EC2 instances.
Key Features
Infrastructure as Code (Terraform): Fully automated provisioning of VPC, subnets, route tables, security groups, IAM roles, Launch Template, Auto Scaling Group, and Application Load Balancer.

Secure Network Design: Public and private subnets across multiple AZs, private EC2 instances without public IPs, and security groups that restrict traffic to only what is required.

REST API Service: Lightweight Node.js/Python API running on port 8080, exposing / for a basic response and /health for ALB health checks.

Load Balancing & Auto Scaling: Application Load Balancer in public subnets routing traffic to an Auto Scaling Group in private subnets, with health checks and high availability configuration.

Outbound Internet Access from Private Subnets: NAT setup to allow instances in private subnets to download updates and dependencies without exposing them directly to the internet.

One-Click Deploy & Destroy: Shell scripts to run terraform apply and terraform destroy, enabling quick spin-up and teardown to control AWS costs.

Cloud-Native Observability Ready: EC2 IAM role prepared for CloudWatch Logs and SSM, allowing centralized logging and secure instance access without opening SSH to the world.

Repository Structure
app/ – REST API source code (Node.js or Python) with / and /health endpoints.

terraform/ – Terraform configuration for all AWS resources (network, ALB, ASG, IAM, security groups, etc.).

scripts/ – Helper scripts for one-click deployment, teardown, and optional automated testing (e.g. health check calls).

README.md – Documentation for setup, deployment, testing, teardown, and architecture overview, including reference screenshots from the AWS console.

Use Cases
Demonstrating end-to-end DevOps skills: IaC, AWS networking, security, and application deployment.

Learning or showcasing how to deploy a private application tier behind an ALB using Terraform.

Serving as a starting point for more advanced features like HTTPS termination, blue–green deployments, or CI/CD integration with GitHub Actions.



