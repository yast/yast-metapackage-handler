# Sources for metapackage

module_DATA = \
  modules/UserSettings.rb \
  modules/OneClickInstallWidgets.rb \
  modules/OneClickInstall.rb \
  modules/OneClickInstallWorkerResponse.rb \
  modules/OneClickInstallWorkerFunctions.rb \
  modules/YPX.pm

client_DATA = \
  clients/OneClickInstallWorker.rb \
  clients/OneClickInstallUrlHandler.rb \
  clients/OneClickInstallCLI.rb \
  clients/OneClickInstallUI.rb

EXTRA_DIST = $(module_DATA) $(client_DATA)

include $(top_srcdir)/Makefile.am.common