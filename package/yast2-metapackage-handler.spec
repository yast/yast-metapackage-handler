# norootforbuild

%define _prefix	/usr

Name:				yast2-metapackage-handler
Version:			0.3
Release:			0.suse%(echo "%{suse_version}" | %__sed -e 's/.$//')
Summary:			YaST2 MetaPackage Parser
Source:			mp.tar.gz
URL:				http://en.opensuse.org/MetaPackage-design
Group:			System/YaST
License:			GNU General Public License (GPL)
BuildRoot:		%{_tmppath}/build-%{name}-%{version}
BuildArch:		noarch
Requires:		yast2-packager perl-XML-Simple
# LWP::Simple, Net::HTTP
Requires:		perl-libwww-perl

%description
YaST2 MetaPackage Parser.

Authors:
--------
    Benjamin Weber

%prep
%setup -q -n "mp"

%build

%install
%__install -d "%{buildroot}%{_datadir}/YaST2/modules"
%__install -m0644 MetaPackageParser.pm "%{buildroot}%{_datadir}/YaST2/modules/"
%__install -d "%{buildroot}%{_datadir}/YaST2/clients"
%__install -m0644 *.ycp "%{buildroot}%{_datadir}/YaST2/clients/"

%clean
%__rm -rf "%{buildroot}"

%files
%defattr(-,root,root)
%doc README COPYING tuxsaver.html tuxsaver.ymp
%dir %{_datadir}/YaST2
%dir %{_datadir}/YaST2/modules
%{_datadir}/YaST2/modules/MetaPackageParser.pm
%dir %{_datadir}/YaST2/clients
%{_datadir}/YaST2/clients/*.ycp

# Local Variables:
# mode: rpm-spec
# tab-width: 3
# End:
