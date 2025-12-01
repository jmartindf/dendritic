{
  coreutils,
  writeShellApplication,
}:
writeShellApplication {
  name = "fqdn";
  text = # bash
    ''
      if [[ -e /etc/fqdn ]];
      then
        ${coreutils}/bin/cat /etc/fqdn
      fi
    '';
}
