# simple makefile to recreate the tarball from the svn
FILES=\
 Makefile \
 \
 config \
 COPYING \
 kdesu.desktop \
 konqueror \
 konquerorrc \
 MetaPackageHandler.ycp \
 MetaPackageParser.pm \
 MetaPackageUrlHandler.ycp \
 MetaPackageWorker.ycp \
 PackageSearch.ycp \
 README \
 SearchClient.pm \
 tuxsaver.html \
 tuxsaver.ymp \
 yast2.desktop \
 ymp.desktop \
 ymu.desktop

PACKAGE=mp
DISTDIR=.dist
dist:
	rm -rf $(DISTDIR)
	mkdir -p $(DISTDIR)/$(PACKAGE)
	cp -a $(FILES) $(DISTDIR)/$(PACKAGE)
	cd $(DISTDIR) && tar cvfz ../package/mp.tar.gz $(PACKAGE)
	rm -rf $(DISTDIR)
