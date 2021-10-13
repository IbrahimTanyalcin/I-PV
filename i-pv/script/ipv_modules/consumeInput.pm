#!/usr/bin/perl
package ipv_modules::consumeInput;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(consumeInput);
our $VERSION = 0.01;

sub consumeInput {
	my ($propsRef, $objRef, $options) = @_;
	my $orObjRef = $objRef;
	my @props = @{$propsRef};
	my $retVal = undef;
	my $callback = sub { return $_[0];};
	my $ask = 0;
	if(ref $options ne "HASH") {
		$options = {};
	}
	if (exists $options -> {ask}){
		if(ref ($options -> {ask}) eq "CODE") {
			$ask = !!($options -> {ask} -> (undef, $objRef));
		} else{
			$ask = !!($options -> {ask});
		}
	}
	if (
		exists $options -> {callback} 
		and (ref ($options -> {callback}) eq "CODE")
	){
		$callback = $options -> {callback};
	}
	
	if ($ask) {
		$retVal = <STDIN>;
		chomp $retVal;
	} else {
		foreach my $prop (@props) {
			if(ref $objRef eq "HASH"){
				$retVal = $objRef = $objRef -> {$prop};
			} elsif (ref $objRef eq "ARRAY"){
				$retVal = $objRef = @{$objRef}[$prop];
			} else {
				$retVal = undef;
				last;
			}
		}
	}
	return $callback -> ($retVal, $orObjRef, $propsRef);
}

qq{
	0042 0065 006e 0020 0079 006f 006c 0063 0075 006c 0075 006b 0020 0075 0073 0074 0061 0073 0131 0079 0131 006d
	0048 0065 0072 0020 0067 0065 006d 0069 006e 0069 006e 0020 0074 0061 0079 0066 0061 0073 0131 0079 0131 006d
	0042 0065 006e 0069 006d 0020 0064 00fc 006e 0079 0061 006d 0020 006b 0075 015f 0062 0061 006b 0131 015f 0131
	0042 0065 006e 0020 0067 0065 006d 0069 006e 0069 006e 0020 006d 0061 0072 0074 0131 0073 0131 0079 0131 006d
	                                             0046 0065 0072 0068 0061 006e 0020 015e 0065 006e 0073 006f 0079
};