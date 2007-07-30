
client_DATA = \
	OneClickInstallUI.ycp \
	OneClickInstallWorker.ycp \
	OneClickInstallUrlHandler.ycp

module_DATA = \
	OneClickInstall.ycp \
	OneClickInstallWorkerResponse.ycp \
	YPX.pm

dist_sbin_SCRIPTS = OneClickInstallUrlHandler

EXTRA_DIST = $(client_DATA) $(module_DATA)

# module compilation
include $(top_srcdir)/Makefile.am.common
