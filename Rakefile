require "yast/rake"

Yast::Tasks.configuration do |conf|
  #lets ignore license check for now
  conf.skip_license_check << /.*/
  conf.install_locations["doc/*"] = conf.install_doc_dir
  conf.install_locations["bin/*"] = File.join(Packaging::Configuration::DESTDIR, "/usr/bin/")
  conf.install_locations["desktop/*"] = File.join(Packaging::Configuration::DESTDIR, "/usr/share/applications/")
  conf.install_locations["mime/*"] = File.join(Packaging::Configuration::DESTDIR, "/usr/share/mime/packages/")
end
