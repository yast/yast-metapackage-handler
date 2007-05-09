 #!/usr/bin/perl -w

package MetaPackageParser;

use XML::Simple;
use Data::Dumper;
use Net::HTTP;
use LWP::Simple;
use LWP::UserAgent;
our %TYPEINFO;

BEGIN { $TYPEINFO{GetMetaPackage} = ["function", ["map","string","any"],"string"]; }
# usage GetMetaPackage(url);
# returns map<string,any>
sub GetMetaPackage
{
	my ($package,$url) = @_;
	my $request = HTTP::Request->new(GET => $url);
	$request->remove_header('Content-Length');
	$browser = LWP::UserAgent->new(keep_alive => 1);
	$browser->timeout(10);
	my $response = $browser->request($request);
	$xml = $response->content();

	#print Dumper($xml);
	$xmlparser = new XML::Simple(ForceArray => 1);
	$data = $xmlparser->XMLin($xml);
	#print Dumper($data);
	return $data;
}

sub GotData
{
	my ($package,$data) = @_;
	print $data;
}
1;

