 #!/usr/bin/perl -w

package YPX;

#use Data::Dumper;
use XML::XPath;
use XML::XPath::XMLParser;

our %TYPEINFO;

BEGIN { $TYPEINFO{Load} = ["function","any","string"]; }

sub Load
{
	my ($package,$url) = @_;
	return XML::XPath->new(filename => $url);
}

BEGIN { $TYPEINFO{SelectValue} = ["function","string","any","string"]; }
sub SelectValue
{
	my ($package,$xp,$xpath) = @_;
	my $value = $xp->getNodeText($xpath)->value();
	return $value;
}

BEGIN { $TYPEINFO{SelectValues} = ["function",["list","string"],"any","string"]; }
sub SelectValues
{
	my ($package,$xp,$xpath) = @_;
	my $nodes = $xp->findnodes($xpath);
	my $values = [];
    foreach my $node ($nodes->get_nodelist) {
		push(@$values,$node->string_value());
    }

	return $values;
}


sub GotData
{
	my ($package,$data) = @_;
	print $data;
}
1;

