{
  coreutils,
  writeShellApplication,
}:
writeShellApplication {
  name = "fqdn";
  text = # bash
    ''
      if [[ -a /etc/fqdn ]];
      then
        ${coreutils}/bin/cat /etc/fqdn
      fi
    '';
}
