#!/bin/sh
ca_key="${1:-../self-signed-ca-example/private/example-self-signed-ca.key}"
ca_crt="${2:-../self-signed-ca-example/example-self-signed-ca.crt}"

set -x
res_file=res-signed.xml

# Sign SAMLResponse
./build-res-xml.sh "$ca_key" "$ca_crt" > "$res_file"

# Validate SAMLResponse using local schema
xmllint --noout --schema saml-schema-protocol-2.0.xsd "$res_file"

# Verify SAMLResponse
xmlsec1 --verify --trusted-pem "$ca_crt" --id-attr:ID urn:oasis:names:tc:SAML:2.0:protocol:Response "$res_file"
