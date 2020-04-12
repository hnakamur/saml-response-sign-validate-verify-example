saml-response-sign-validate-verify-example
==========================================

An example script for signing, validating, and verifying SAMLResponse.

## Setup

On Ubuntu, install `libxml2-utils` and `xmlsec1`.

```
sudo apt-get install libxml2-utils xmlsec1
```

Clone this respoitory.

```
git clone https://github.com/hnakamur/saml-response-sign-validate-verify-example
```

Also clone the repository to create an example self-signed CA certificate.

```
git clone https://github.com/hnakamur/self-signed-ca-example
```

Follow the steps on README in that repository to create a CA certificate.

## Run the example script

```
./run.sh
```

This script generate a signed SAMLResponse to the file `res-signed.xml`,
validate it using local schema files, and verify it.

## Modifications added to local schema files.

XML Schema files are downloaded from the following URLs.

* http://docs.oasis-open.org/security/saml/v2.0/saml-2.0-os.zip
  on https://wiki.oasis-open.org/security/FrontPage
  (Note: You should check the latest Approved Errata there).
* http://www.w3.org/TR/2008/REC-xmldsig-core-20080610/xmldsig-core-schema.xsd
  on https://www.w3.org/TR/xmldsig-core1/
* https://www.w3.org/TR/xmlenc-core1/xenc-schema.xsd
  on https://www.w3.org/TR/xmlenc-core1/

Then I modified `schemaLocation` attributes of `import` tags to
local filenames like below:

```
diff --git a/saml-schema-assertion-2.0.xsd b/saml-schema-assertion-2.0.xsd
index 6aa3b27..478ddfa 100644
--- a/saml-schema-assertion-2.0.xsd
+++ b/saml-schema-assertion-2.0.xsd
@@ -10,9 +10,9 @@
     blockDefault="substitution"
     version="2.0">
     <import namespace="http://www.w3.org/2000/09/xmldsig#"
-        schemaLocation="http://www.w3.org/TR/2002/REC-xmldsig-core-20020212/xmldsig-core-schema.xsd"/>
+        schemaLocation="xmldsig-core-schema.xsd"/>
     <import namespace="http://www.w3.org/2001/04/xmlenc#"
-        schemaLocation="http://www.w3.org/TR/2002/REC-xmlenc-core-20021210/xenc-schema.xsd"/>
+        schemaLocation="xenc-schema.xsd"/>
     <annotation>
         <documentation>
             Document identifier: saml-schema-assertion-2.0
diff --git a/saml-schema-protocol-2.0.xsd b/saml-schema-protocol-2.0.xsd
index eb480e5..e6be1e4 100644
--- a/saml-schema-protocol-2.0.xsd
+++ b/saml-schema-protocol-2.0.xsd
@@ -12,7 +12,7 @@
     <import namespace="urn:oasis:names:tc:SAML:2.0:assertion"
         schemaLocation="saml-schema-assertion-2.0.xsd"/>
     <import namespace="http://www.w3.org/2000/09/xmldsig#"
-        schemaLocation="http://www.w3.org/TR/2002/REC-xmldsig-core-20020212/xmldsig-core-schema.xsd"/>
+        schemaLocation="xmldsig-core-schema.xsd"/>
     <annotation>
         <documentation>
             Document identifier: saml-schema-protocol-2.0
diff --git a/xenc-schema.xsd b/xenc-schema.xsd
index 5d1a2d7..6f2a3de 100644
--- a/xenc-schema.xsd
+++ b/xenc-schema.xsd
@@ -32,7 +32,7 @@
         elementFormDefault='qualified'>
 
   <import namespace='http://www.w3.org/2000/09/xmldsig#'
-          schemaLocation='http://www.w3.org/TR/2002/REC-xmldsig-core-20020212/xmldsig-core-schema.xsd'/>
+          schemaLocation='xmldsig-core-schema.xsd'/>
 
   <complexType name='EncryptedType' abstract='true'>
     <sequence>
```
