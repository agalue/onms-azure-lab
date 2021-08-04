# onms-azure-lab

This is a simple test environment running in Azure made with [Terraform](https://www.terraform.io/) to provide the following:

- A VM with the latest OpenNMS Horizon and PostgreSQL 10
  - All the Telemetryd listeners enabled
  - Kafka for Sink and RPC
  - Kafka Producer feature enabled
  - RRDtool for metrics with `storeByGroup` and `storeByForeignSource` enabled
- A VM with Elasticsearch 7.6.2 and Kibana 7.6.2 for Flow Processing
  - OpenNMS Drift Plugin installed
- A VM with Zookeeper 3.5, Kafka 2.8.0, and CMAK (started via Docker).

All VMs are based on CentOS 8 and will be initialized via [cloud-init](https://cloudinit.readthedocs.io/en/latest/) scripts modified at runtime by Terraform based on the chosen variables.

All VMs will have valid FQDN in the `cloudapp.azure.com` domain to facilitate configuring Minions and accessing the applications.

All VMs will have the Net-SNMP agent configured and running.

For instance, if `location=eastus` and `username=agalue`, the FQDNs would be:

* `agalue-onms.eastus.cloudapp.opennms.com` (WebUI=8980, Grafana=3000, SSH=22)
* `agalue-kafka.eastus.cloudapp.opennms.com` (Client=9094)
* `agalue-elastic.eastus.cloudapp.opennms.com` (Kibana=5601)

## Start the lab

* Make sure to have the Azure CLI installed on your system and then:

```bash
az login
```

* Initialize Terraform

```bash
terraform init
```

* Review [vars.tf](./vars.tf) in case you want to alter something

* Create the resources in Azure

```bash
terraform apply \
  -var "username=agalue" \
  -var "password=1HateWind0ws;" \
  -var "email=agalue@opennms.org"
```

The above assumes there is already a resource group called `support-testing` created in Azure, on which Terraform will create all the resources.

If you want to create the resource group, you can run the following instead:

```bash
terraform apply \
  -var "username=agalue" \
  -var "password=1HateWind0ws;" \
  -var "email=agalue@opennms.org" \
  -var "resource_group_create=true" \
  -var "resource_group_name=OpenNMS"
```

Additionally, if you want to enable SCRAM authentication for Kafka and TLS Encrytion via LetsEncrypt for OpenNMS and Kafka, add `-var "security.enabled=true"` to the list of variables.

All the resources will be prefixed by the content of the `username` variable for their names.

The provided credentials will give you SSH access to all the machines, and remember that you can use the generated FQDNs (as all the IP addresses, public and private, are dynamic).

The chosen `password` for authentication must follow the Azure guidelines; otherwise, the resource creation will fail. Fortunately, you can re-apply the changes with the correct one on the next attempt.

For testing purposes, this repository provides a `cloud-init` YAML file for Minion, you can use with [multipass](https://multipass.run/). It contains some templating variables you can replace using [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html); for instance:

```bash
export user="agalue"
export azure_location="eastus"
export minion_id="minion01"
export minion_location="Apex"
export minion_heap="1g"

envsubst < minion-template.yaml > /tmp/$minion_id.yaml
multipass launch -m 2G -n $minion_id --cloud-init /tmp/$minion_id.yaml
```

The template assumes you haven't changed the `locals` entry inside `vars.tf`.

## Destroy the lab

To destroy all the resources, you should execute the `terraform destroy` command with the same variables you used when executed `terraform apply`, for instance:

```bash
terraform destroy -var "username=agalue" -var "password=1HateWind0ws;"
```

Or,

```bash
terraform destroy \
  -var "username=agalue" \
  -var "password=1HateWind0ws;" \
  -var "resource_group_create=true" \
  -var "resource_group_name=OpenNMS"
```
