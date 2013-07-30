dist_sbin_SCRIPTS = \
	OneClickInstallUrlHandler \
	OneClickInstallCLI

install-exec-hook:
	$(LN_S) -f OneClickInstallUrlHandler $(DESTDIR)$(sbindir)/OneClickInstallUI 
	$(LN_S) -f OneClickInstallCLI $(DESTDIR)$(sbindir)/OCICLI

