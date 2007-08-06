
client_DATA = \
	OneClickInstallUI.ycp \
	OneClickInstallWorker.ycp \
	OneClickInstallUrlHandler.ycp

module_DATA = \
	OneClickInstall.ycp \
	OneClickInstallWorkerResponse.ycp \
	YPX.pm

dist_sbin_SCRIPTS = OneClickInstallUrlHandler

old_distro_Data = kdeymp.desktop x-suse-ymp.desktop

EXTRA_DIST = $(client_DATA) $(module_DATA) $(old_distro_Data)

# module compilation
include $(top_srcdir)/Makefile.am.common
