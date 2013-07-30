 #!/usr/bin/perl -w

package YPX;

#use Data::Dumper;
use XML::XPath;
use XML::XPath::XMLParser;
use YaST::YCP;

our %TYPEINFO;

BEGIN { $TYPEINFO{Load} = ["function","any","string"]; }
sub Load
{
	my $xml_result;
	#try
	eval
	{
		my ($package,$url) = @_;
		$xml_result = XML::XPath->new(filename => $url);
	};
	#catch (Throwable t)
	if ($@)
	{
		return YaST::YCP::Boolean(0);
	};
	return $xml_result;
}

BEGIN { $TYPEINFO{SelectValue} = ["function","string","any","string"]; }
sub SelectValue
{
	my $xml_result;
	#try
	eval
	{
		my ($package,$xp,$xpath) = @_;
		$xml_result = $xp->getNodeText($xpath)->value();
	};
	#catch (Throwable t)
	if ($@)
	{
		return;
	};
	return $xml_result;
}

BEGIN { $TYPEINFO{SelectValues} = ["function",["list","string"],"any","string"]; }
sub SelectValues
{
	my $xml_result = [];
	#try
	eval
	{
		my ($package,$xp,$xpath) = @_;
		my $nodes = $xp->findnodes($xpath);
		foreach my $node ($nodes->get_nodelist) {
			push(@$xml_result,$node->string_value());
		}
	};
	#catch (Throwable t)
	if ($@)
	{
		return;
	};
	return $xml_result;
}


sub GotData
{
	my ($package,$data) = @_;
	print $data;
}
1;

