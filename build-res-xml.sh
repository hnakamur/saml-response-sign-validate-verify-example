#!/bin/sh
if [ $# -ne 2 ]; then
  echo "Usage: $0 ca_key ca_crt" 1>&2
  exit 2
fi

ca_key="$1"
ca_crt="$2"

request_id="_$(openssl rand -hex 16)"
assertion_id="_a_$(openssl rand -hex 16)"
session_id="_s_$(openssl rand -hex 16)"
response_id="_EXAMPLE_SSO_$(cat /proc/sys/kernel/random/uuid)"

now="$(date --utc +%Y-%m-%dT%H:%M:%SZ)"
not_on_or_before="$(date --utc +%Y-%m-%dT%H:%M:%SZ --date '-5 minutes')"
not_on_or_after="$(date --utc +%Y-%m-%dT%H:%M:%SZ --date '+5 minutes')"
session_not_on_or_after="$(date --utc +%Y-%m-%dT%H:%M:%SZ --date '+24 hours')"

tmp_dir="$(mktemp -d /tmp/sign-saml-res.XXXXXXXXXX)"
trap "rm -r '$tmp_dir'" EXIT

tmp_res_file="$tmp_dir/res-unsigned.xml"

sed -e "
s|{{ idp_issuer }}|https://idp.example.com/saml2|
s|{{ sp_issuer }}|https://sp.example.com/sso|
s|{{ destination }}|https://sp.example.com/sso/saml2|
s/{{ request_id }}/$request_id/
s/{{ response_id }}/$response_id/
s/{{ assertion_id }}/$assertion_id/
s/{{ session_id }}/$session_id/
s/{{ now }}/$now/
s/{{ not_on_or_before }}/$not_on_or_before/
s/{{ not_on_or_after }}/$not_on_or_after/
s/{{ session_not_on_or_after }}/$session_not_on_or_after/
s/{{ nameid_format }}/urn:oasis:names:tc:SAML:1.1:nameid-format:persistent/
s/{{ name_qualifier }}/sso.example.com/
s/{{ name_id }}/john-doe/
s|{{ audience }}|https://sp.example.com/sso|
s/{{ authn_context_class_ref }}/urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport/
/{% for key, value in attributes.items %}/d
s/{{ key }}/mail/
s/{{ value }}/john-doe@example.com/
/{% endfor %}/d
" res-tmpl.xml > "$tmp_res_file"

xmlsec1 --sign --privkey-pem "$ca_key,$ca_crt" --id-attr:ID urn:oasis:names:tc:SAML:2.0:protocol:Response "$tmp_res_file"
