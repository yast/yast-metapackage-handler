
client_DATA = \
	OneClickInstallUI.ycp \
	OneClickInstallWorker.ycp \
	OneClickInstallUrlHandler.ycp

module_DATA = \
	OneClickInstall.ycp \
	OneClickInstallWorkerResponse.ycp \
	YPX.pm

dist_sbin_SCRIPTS = OneClickInstallUrlHandler
install-exec-hook:
	$(LN_S) OneClickInstallUrlHandler $(DESTDIR)$(sbindir)/OneClickInstallUI

old_distro_Data = kdeymp.desktop x-suse-ymp.desktop

mimedir = $(datadir)/mime/packages
mime_DATA = yast2-metapackage-handler-mimetypes.xml

# overrides devtools
desktopdir = $(datadir)/applications
desktop_DATA = yast2-metapackage-handler.desktop yast2-metapackage-handler-ymu.desktop

EXTRA_DIST = $(client_DATA) $(module_DATA) $(old_distro_Data) $(mime_DATA) $(desktop_DATA)

# module compilation
include $(top_srcdir)/Makefile.am.common
