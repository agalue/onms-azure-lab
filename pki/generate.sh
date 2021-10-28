#!/bin/bash

echo "Generating Root CA"
cat <<EOF | cfssl gencert -initca - | cfssljson -bare ca-root
{
  "CN": "Root OpenNMS CA",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "ST": "NC",
      "O": "The OpenNMS Group, Inc."
    }
  ]
}
EOF

echo
echo "Generating Intermediate CA"
cat <<EOF | cfssl genkey -initca - | cfssljson -bare ca-intermediate
{
  "CN": "OpenNMS IT/Support (Intermediate)",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "ST": "NC",
      "O": "The OpenNMS Group, Inc.",
      "OU": "Support"
    }
  ]
}
EOF
cfssl sign -ca ca-root.pem -ca-key ca-root-key.pem --config config.json -profile authority ca-intermediate.csr | cfssljson -bare ca-intermediate

echo
echo "Done!"
