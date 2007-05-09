 #!/usr/bin/perl -w

package SearchClient;

use XML::Simple;
use Data::Dumper;
use LWP::Simple;
use LWP::UserAgent;
our %TYPEINFO;

BEGIN { $TYPEINFO{Search} = ["function", ["list",["map","string",["list","any"]]], "string","string"]; }
# usage Search(searchHost,searchUrl,searchTerm);
# returns list<map<string,<list<any>>>
# mostly list<map<string,<list<string>>>
sub Search
{
	my ($package,$url,$searchterm) = @_;
	my $request = HTTP::Request->new(GET => $url . $searchterm);
	print $url;
	$browser = LWP::UserAgent->new(keep_alive => 1);
	$browser->timeout(10);
	my $response = $browser->request($request);
	$xml = $response->content();
	
	$xmlparser = new XML::Simple(ForceArray => 1);
	$data = $xmlparser->XMLin($xml);
	#print Dumper($data);
	$packageList = $data->{"package"};
	return $packageList;
}

1;
