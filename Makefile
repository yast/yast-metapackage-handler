# simple makefile to recreate the tarball from the svn
FILES=\
 Makefile \
 \
 COPYING \
 MetaPackageHandler.ycp \
 MetaPackageParser.pm \
 MetaPackageUrlHandler.ycp \
 MetaPackageWorker.ycp \
 README \
 tuxsaver.html \
 tuxsaver.ymp

PACKAGE=mp
DISTDIR=.dist
dist:
	rm -rf $(DISTDIR)
	mkdir -p $(DISTDIR)/$(PACKAGE)
	cp -a $(FILES) $(DISTDIR)/$(PACKAGE)
	cd $(DISTDIR) && tar cvfz ../package/mp.tar.gz $(PACKAGE)
	rm -rf $(DISTDIR)
