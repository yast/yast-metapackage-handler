dist_sbin_SCRIPTS = \
	OneClickInstallUrlHandler \
	OneClickInstallCLI

install-exec-hook:
	$(LN_S) -f OneClickInstallUrlHandler $(DESTDIR)$(sbindir)/OneClickInstallUI
	$(LN_S) -f OneClickInstallCLI $(DESTDIR)$(sbindir)/OCICLI
# backward compatibility with binaries in /sbin
	mkdir -p $(DESTDIR)/sbin/
	$(LN_S) -f $(sbindir)/OneClickInstallCLI $(DESTDIR)/sbin/OCICLI
	$(LN_S) -f $(sbindir)/OneClickInstallCLI $(DESTDIR)/sbin/OneClickInstallCLI
	$(LN_S) -f $(sbindir)/OneClickInstallUrlHandler $(DESTDIR)/sbin/OneClickInstallUI
	$(LN_S) -f $(sbindir)/OneClickInstallUrlHandler $(DESTDIR)/sbin/OneClickInstallUrlHandler


