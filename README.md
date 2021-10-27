# onms-azure-lab

This is a simple test environment running in Azure made with [Terraform](https://www.terraform.io/) to provide the following:

- A VM with the latest OpenNMS Horizon and PostgreSQL 10
  - All the Telemetryd listeners enabled
  - Kafka for Sink and RPC
  - Kafka Producer feature enabled
  - RRDtool for metrics with `storeByGroup` and `storeByForeignSource` enabled
- A VM with Elasticsearch 7.6.2 and Kibana 7.6.2 for Flow Processing
  - OpenNMS Drift Plugin installed
- A VM with Zookeeper 3.5, Kafka 2.8.1, and CMAK (started via Docker).

All VMs are based on CentOS 8 and will be initialized via [cloud-init](https://cloudinit.readthedocs.io/en/latest/) scripts modified at runtime by Terraform based on the chosen variables.

All VMs will have valid FQDN in the `cloudapp.azure.com` domain to facilitate configuring Minions and accessing the applications.

All VMs will have the Net-SNMP agent configured and running.

For instance, if `location=eastus` and `name_prefix=ag-lab1`, the FQDNs would be:

* `ag-lab1-onms.eastus.cloudapp.opennms.com` (with `security.enabled=false` OpenNMS WebUI=8980 and Grafana=3000; with `security.enabled=true`, both available at 443 via Nginx, using `/opennms` for OpenNMS and `/grafana` for Grafana)
* `ag-lab1-kafka.eastus.cloudapp.opennms.com` (Client=9094, CMAK=9000)
* `ag-lab1-elastic.eastus.cloudapp.opennms.com` (Kibana=5601)

All instances have SSH access.

## Start the lab

* Make sure to have the Azure CLI installed on your system and then:

```bash
az login
```

* Initialize Terraform

```bash
terraform init
```

* Initialize PKI for Private CAs

```bash
cd pki/
./generate.sh
cd ..
```

> Failing on this will prevent Terraform from deploying the resources, even if you're planning to use LetsEncrypt.

* Review [vars.tf](./vars.tf) in case you want to alter something

* Create the resources in Azure

```bash
terraform apply \
  -var "name_prefix=ag-lab1" \
  -var "username=agalue" \
  -var "password=1HateWind0ws;" \
  -var "email=agalue@opennms.org"
```

The above assumes there is already a resource group called `support-testing` created in Azure, on which Terraform will create all the resources.

If you want to create the resource group, enable security and change other settings, we recommend to use a `.tfvars` file, for instance:

```bash
cat <<EOF > custom.tfvars
name_prefix = "ag-lab1"
username = "agalue"
password = "1HateWind0ws;"
email = "agalue@opennms.org"
resource_group = {
  create = true
  name   = "OpenNMS"
}
security = {
  enabled      = true
  use_pki      = true
  zk_user      = "zkonms"
  zk_passwd    = "zk0p3nNM5;"
  kafka_user   = "opennms"
  kafka_passwd = "0p3nNM5;"
  jks_passwd   = "jks0p3nNM5;"
  cmak_user    = "opennms"
  cmak_passwd  = "cmak0p3nNM5;"
}
EOF

terraform apply -var-file="custom.tfvars"
```

When enabling security, the `cloud-init` scripts will enable SCRAM authentication for Kafka. If `use_pki=false` it enables TLS Encryption via LetsEncrypt for OpenNMS/Grafana via Nginx and Kafka; otherwise, it will use PKI based on the certificates from the [pki](./pki) directory.

All the resources will be prefixed by the content of the `name_prefix` variable for their names.

The provided credentials will give you SSH access to all the machines, and remember that you can use the generated FQDNs (as all the IP addresses, public and private, are dynamic).

The chosen `password` for authentication must follow the Azure guidelines; otherwise, the resource creation will fail. Fortunately, you can re-apply the changes with the correct one on the next attempt.

If you want to install a specific version of OpenNMS, you should provide a value for the variable `onms_repo` (defaults to `stable`) and `onms_version` (defaults to `latest`). The values for `onms_repo` can only be `stable`, `oldstable`, `obsolete`, or `bleeding`. The version must be either `latest` or a specific number following RPM convention, for instance, `27.2.0-1`.

For testing purposes, you can start a Minion with Docker using the provided script which assumes PKI, which is the most complex scenario:

```bash
./start-minion.sh \
  --minion_location "Apex" \
  --minion_id "ag-minion01" \
  --opennms_url "https://ag-lab1-onms.eastus.cloudapp.azure.com/opennms" \
  --kafka_boostrap "ag-lab1-kafka.eastus.cloudapp.azure.com:9094" \
  --kafka_user "opennms" \
  --kafka_passwd "0p3nNM5;" \
  --jks_passwd "0p3nNM5"
```
```

> Ensure the usage of the appropriate content based on how you started the lab.

## Destroy the lab

To destroy all the resources, you should execute the `terraform destroy` command with the same variables you used when executed `terraform apply`.
