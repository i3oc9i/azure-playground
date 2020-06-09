# JUMPBOX Virtual Machine

Jumpbox is a VM providing tools to install and manage VMWare TKGI (aka Pivotal PKS) on AZURE.

Just setup the ./Terraform/terraform.tfvars accordingly,then run 'terraform apply' to deploy it.


## Terrafom troubleshooting

```
export TF_LOG = TRACE, DEBUG, INFO WARN or ERROR
export TF_LOG_PATH = /tmp/...
```

