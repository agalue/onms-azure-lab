#!/bin/bash

minion_location="Apex"
minion_id="ag-minion01"
opennms_url="https://ag-lab1-onms.eastus.cloudapp.azure.com/opennms"
kafka_boostrap="ag-lab1-kafka.eastus.cloudapp.azure.com:9094"
kafka_user="opennms"
kafka_passwd="0p3nNM5;"
jks_passwd="0p3nNM5"

# Processing parameters
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

# Build Trust Store
jks_file="onms-pki.jks"
rm -f $jks_file
echo "yes" | keytool -importcert -alias ca-intermediate \
  -file pki/ca-intermediate.pem -storepass "${jks_passwd}" -keystore $jks_file
echo "yes" | keytool -importcert -alias ca-root \
  -file pki/ca-root.pem -storepass "${jks_passwd}" -keystore $jks_file

cat <<EOF > minion.yaml
http-url: "${opennms_url}"
id: "${minion_id}"
location: "${minion_location}"
ipc:
EOF
for module in rpc sink; do
  cat <<EOF >> minion.yaml
  $module:
    kafka:
      single-topic: 'true'
      bootstrap.servers: '${kafka_boostrap}'
      security.protocol: 'SASL_SSL'
      sasl.mechanism: 'SCRAM-SHA-512'
      sasl.jaas.config: 'org.apache.kafka.common.security.plain.PlainLoginModule required username="${kafka_user}" password="${kafka_passwd}";'
      ssl.truststore.location: /opt/minion/etc/$jks_file
      ssl.truststore.password: ${jks_passwd}
EOF
done

docker run --name minion -it --rm \
 -e OPENNMS_HTTP_USER=admin \
 -e OPENNMS_HTTP_PASS=admin \
 -e JAVA_OPTS="-Djavax.net.ssl.trustStore=/opt/minion/etc/$jks_file -Djavax.net.ssl.trustStorePassword=${jks_passwd}" \
 -p 8201:8201 \
 -p 1514:1514/udp \
 -p 1162:1162/udp \
 -p 8877:8877/udp \
 -p 11019:11019 \
 -v $(pwd)/$jks_file:/opt/minion/etc/$jks_file \
 -v $(pwd)/minion.yaml:/opt/minion/minion-config.yaml \
 opennms/minion:28.1.1 -c
