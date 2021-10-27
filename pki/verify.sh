#!/bin/bash

echo "### Root CA ..."
openssl x509 -in ca-root.pem -text -noout

echo "### Intermediate CA ..."
openssl x509 -in ca-intermediate.pem -text -noout

