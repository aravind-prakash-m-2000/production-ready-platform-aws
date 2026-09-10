# Terraform bootstrap

Create the remote state bucket and lock table **once** per AWS account:

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="state_bucket_name=YOUR_UNIQUE_BUCKET"
```

Copy the bucket name into `backend "s3"` blocks in:

- `terraform/environments/dev/main.tf`
- `terraform/environments/prod/main.tf`

Then:

```bash
cd ../environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

Restrict `public_access_cidrs` before any production apply.
