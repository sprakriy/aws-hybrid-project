# Choose a unique name, e.g., my-hybrid-lab-tfstate-12345
aws s3 mb s3://sp-01102026-aws-kub --region us-east-1

# Enable versioning (Important! If you mess up a state file, you can go back)
aws s3api put-bucket-versioning --bucket sp-01102026-aws-kub --versioning-configuration Status=Enabled