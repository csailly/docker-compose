#!/bin/bash

set -o nounset \
  -o errexit

if [ -n $(which java) ]; then
  echo "Java installed."
else
  echo "Java NOT installed!"
  exit 1
fi

printf "Deleting previous (if any)..."
rm -rf kafka/secrets
mkdir -p kafka/secrets
mkdir -p tmp
echo " OK!"
# Generate CA key
printf "Creating CA..."
openssl req -new -x509 -keyout tmp/mycompany-ca.key -out tmp/mycompany-ca.crt -days 365 -subj '/CN=ca.mycompany/OU=test/O=mycompany/L=lille/C=fr' -passin pass:mycompany -passout pass:mycompany >/dev/null 2>&1

echo " OK!"

for i in 'broker' 'producer' 'consumer' 'schema-registry'; do
  printf "Creating cert and keystore of $i..."
  # Create keystores
  keytool -genkey -noprompt \
    -alias $i \
    -dname "CN=$i, OU=test, O=mycompany, L=lille, C=fr" \
    -keystore kafka/secrets/$i.keystore.jks \
    -keyalg RSA \
    -storepass mycompany \
    -keypass mycompany >/dev/null 2>&1

  # Create CSR, sign the key and import back into keystore
  keytool -keystore kafka/secrets/$i.keystore.jks -alias $i -certreq -file tmp/$i.csr -storepass mycompany -keypass mycompany >/dev/null 2>&1

  openssl x509 -req -CA tmp/mycompany-ca.crt -CAkey tmp/mycompany-ca.key -in tmp/$i.csr -out tmp/$i-ca-signed.crt -days 365 -CAcreateserial -passin pass:mycompany >/dev/null 2>&1

  keytool -keystore kafka/secrets/$i.keystore.jks -alias CARoot -import -noprompt -file tmp/mycompany-ca.crt -storepass mycompany -keypass mycompany >/dev/null 2>&1

  keytool -keystore kafka/secrets/$i.keystore.jks -alias $i -import -file tmp/$i-ca-signed.crt -storepass mycompany -keypass mycompany >/dev/null 2>&1

  # Create truststore and import the CA cert.
  keytool -keystore kafka/secrets/$i.truststore.jks -alias CARoot -import -noprompt -file tmp/mycompany-ca.crt -storepass mycompany -keypass mycompany >/dev/null 2>&1
  echo " OK!"
done

echo "mycompany" >kafka/secrets/cert_creds
rm -rf tmp

echo "SUCCEEDED"
