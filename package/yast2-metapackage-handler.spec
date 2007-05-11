# norootforbuild

%define _prefix	/usr
%define kdeprefix	/opt/kde3

Name:				yast2-mpp
Version:			0.1
Release:			0.suse%(echo "%{suse_version}" | %__sed -e 's/.$//')
Summary:			YaST2 MetaPackage Parser
Source:			mp.tar.gz
URL:				http://en.opensuse.org/MetaPackage-design
Group:			System/YaST
License:			GNU General Public License (GPL)
BuildRoot:		%{_tmppath}/build-%{name}-%{version}
BuildArch:		noarch
Requires:		yast2-packager perl-XML-Simple kdebase3
# LWP::Simple, Net::HTTP
Requires:		perl-libwww-perl
# kwriteconfig
BuildRequires:		kdebase3

%description
YaST2 MetaPackage Parser.

Authors:
--------
    Benjamin Weber

%prep
%setup -q -n "mp"

%build

%install
%__install -d "%{buildroot}%{kdeprefix}/share/mimelnk/text"
%__install -m0644 ymp.desktop ymu.desktop "%{buildroot}%{kdeprefix}/share/mimelnk/text/"

%__install -D -m0644 yast2.desktop "%{buildroot}%{kdeprefix}/share/applnk/.hidden/yast2.desktop"

%__install -d "%{buildroot}%{_datadir}/YaST2/modules"
%__install -m0644 MetaPackageParser.pm SearchClient.pm "%{buildroot}%{_datadir}/YaST2/modules/"
%__install -d "%{buildroot}%{_datadir}/YaST2/clients"
%__install -m0644 *.ycp "%{buildroot}%{_datadir}/YaST2/clients/"

%post
PROFILERC=%{kdeprefix}/share/config/profilerc
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymp - 1' --key AllowAsDefault --type bool true
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymp - 1' --key Application --type string kde-kdesu.desktop
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymp - 1' --key GenericServiceType --type string Application
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymp - 1' --key Preference --type string 1
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymp - 1' --key ServiceType --type string text/ymp

%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymu - 1' --key AllowAsDefault --type bool true
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymu - 1' --key Application --type string kde-yast2.desktop
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymu - 1' --key GenericServiceType --type string Application
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymu - 1' --key Preference --type string 1
%{kdeprefix}/bin/kwriteconfig --file "$PROFILERC" --group 'text/ymu - 1' --key ServiceType --type string text/ymu

KRC=%{kdeprefix}/share/config/konquerorrc
%{kdeprefix}/bin/kwriteconfig --file "$KRC" --group 'Notification Messages' --key askEmbedOrSavetext/ymp --type string no
%{kdeprefix}/bin/kwriteconfig --file "$KRC" --group 'Notification Messages' --key askEmbedOrSavetext/ymu --type string no
%{kdeprefix}/bin/kwriteconfig --file "$KRC" --group 'Notification Messages' --key askSavetext/ymp --type string no
%{kdeprefix}/bin/kwriteconfig --file "$KRC" --group 'Notification Messages' --key askSavetext/ymu --type string no

%__chmod 644 "$PROFILERC"
%__chmod 644 "$KRC"

%clean
%__rm -rf "%{buildroot}"

%files
%defattr(-,root,root)
%doc README
%{kdeprefix}/share/mimelnk/text/ym?.desktop
%{kdeprefix}/share/applnk/.hidden/yast2.desktop
%dir %{_datadir}/YaST2
%dir %{_datadir}/YaST2/modules
%{_datadir}/YaST2/modules/MetaPackageParser.pm
%{_datadir}/YaST2/modules/SearchClient.pm
%dir %{_datadir}/YaST2/clients
%{_datadir}/YaST2/clients/*.ycp

%changelog
* Thu May 09 2007 Martin Vidner <mvidner@suse.cz>
- autobuild adjustments

* Sat Apr 21 2007 Pascal Bleser <guru@unixtech.be> 0.0-0
- new package

# Local Variables:
# mode: rpm-spec
# tab-width: 3
# End:
