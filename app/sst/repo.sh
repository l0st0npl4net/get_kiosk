#! /bin/sh


HOST=repo.getit.rest
DEBIAN=$(cat /etc/debian_version | tee)
DEBIAN_CODENAME=$(. /etc/os-release && echo $VERSION_CODENAME)

sudo apt-get -y install gnupg

GOT=$(openssl s_client -connect "$HOST:443" -servername "$HOST" </dev/null 2>/dev/null \
      | openssl x509 -outform der | sha256sum | cut -d' ' -f1)

[ "$GOT" = "$FINGERPRINT" ] || { echo "TLS pin mismatch for $HOST: got $GOT" >&2; exit 1; }

sudo cat << EOF > /etc/apt/sources.list.d/bos.list
deb [signed-by=/etc/apt/keyrings/getit-repo-2026.gpg] https://repo.getit.rest/ $DEBIAN_CODENAME main
EOF


wget -O - https://repo.getit.rest/getit-repo-2026.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/getit-repo-2026.gpg
