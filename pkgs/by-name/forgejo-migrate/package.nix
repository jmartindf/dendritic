{
  unzip,
  rsync,
  postgresql_17,
  forgejo-lts,
  writeShellApplication,
}:
let
  fj = "${forgejo-lts}/bin/gitea";
  rsyncc = "${rsync}/bin/rsync";
  unzipp = "${unzip}/bin/unzip";
  psql = "${postgresql_17}/bin/psql";
  work_path = "/var/lib/forgejo/";
  app_ini = "${work_path}custom/conf/app.ini";
  migrate = "${work_path}migrate";
in
writeShellApplication {
  name = "forgejo-migrate";
  text = # bash
    ''
      ${unzipp} ${migrate}/forgejo.zip -d ${migrate}

      rm ${migrate}/data/gitea.db
      echo 'drop owned by forgejo cascade;' | ${psql} --set ON_ERROR_STOP=on forgejo
      ${psql} --set ON_ERROR_STOP=on forgejo < ${migrate}/forgejo-db.sql

      ${rsyncc} --delete-delay --delete --remove-source-files -rav ${migrate}/data/ ${work_path}data/
      ${rsyncc} --delete-delay --delete --remove-source-files -rav ${migrate}/repos/ ${work_path}repositories/

      ${fj} --config ${app_ini} --work-path ${work_path} migrate

      ${fj} --config ${app_ini} \
          --work-path ${work_path} \
          doctor check \
          --all \
          --fix
    '';
}
