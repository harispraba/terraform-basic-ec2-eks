# Terraform Basic

This terraform repository will create EC2 and EKS cluster.

## EC2
Will create EC2 using autoscaling group.

Change directory to `ec2` then run the following commands:

```
terraform init
terraform plan -out=state
terraform apply state
```

The output from apply command will be:
- subnet list to be used to create the EKS cluster

## EKS Cluster
Will create EKS Cluster with one managed nodegroup.

Change directory to `eks` then run the following commands:

```
terraform init
terraform plan -out=state
terraform apply state
```

The output from apply command will be:
- eks cluster endpoint
- certificate authority for kubeconfig

After the cluster is fully created, run the following command to set kubeconfig:
```
aws eks update-kubeconfig --region <region> --name <cluster name>
```

Then test your cluster with kubectl command such as `kubectl get nodes` to list your nodes. 