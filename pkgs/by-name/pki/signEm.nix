{
  lib,
  pki,
  writeShellApplication,
}:
writeShellApplication {
  name = "step-ssh-sign-host-keys";
  text = # bash
    ''
      fqdn="richard.home.thosemartins.family"
      if [[ -a /etc/ssh/ssh_host_ed25519_key ]];
      then
      ${lib.getExe pki.step} ssh certificate --host --host-id machine --sign "$fqdn" /etc/ssh/ssh_host_ed25519_key.pub
      fi
      if [[ -a /etc/ssh/ssh_host_rsa_key ]];
      then
      ${lib.getExe pki.step} ssh certificate --host --host-id machine --sign "$fqdn" /etc/ssh/ssh_host_rsa_key.pub
      fi
    '';
}
