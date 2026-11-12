mkdir -p iso
cd iso
curl -k -O https://files.red-soft.ru/redos/8.0/x86_64/iso/redos-8-20260716.0-Everything-x86_64-DVD1.iso
curl -k -O https://files.red-soft.ru/redos/8.0/x86_64/iso/redos-8-20260716.0-Everything-x86_64-DVD1.iso.MD5SUM
md5sum -c redos-8-20260716.0-Everything-x86_64-DVD1.iso.MD5SUM
