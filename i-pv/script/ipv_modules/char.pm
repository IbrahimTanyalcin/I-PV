#!/usr/bin/perl
package ipv_modules::char;
use strict;
use warnings;
use feature 'say';
use utf8;
use List::Util qw(any);
use Exporter qw(import);

our @EXPORT_OK = qw(oneof isPrintableAscii isExtendedAscii isPrintableOrExtendedAscii);
our $VERSION = 0.01;
 
sub oneof {
	if(uc(ref $_[0]) ne "ARRAY") {
		die "'oneof' expects a reference to an array.\n";
	}
	my $searchString = "[" . join("",
		map {
			"\\N{U+"
			. sprintf("%04X", ord($_))
			. "}"
		}
		@{$_[0]}
	) . "]";
	return qr"$searchString"i;
}

#say "dÀef" =~ oneof([qw(! a b c ቪ À)]);

#https://theasciicode.com.ar/extended-ascii-code/lowercase-letter-u-acute-accent-ascii-code-163.html
sub isPrintableAscii {
	my @chars = map {ord($_)} split("", $_[0]);
	if (grep {$_ < 32 || $_ > 126} @chars){
		return 0;
	}
	return 1;
}

#say isPrintableAscii(" !mn p  ü|} ~");

sub isExtendedAscii {
	my @chars = map {ord($_)} split("", $_[0]);
	if (grep {$_ < 128 || $_ > 255} @chars){
		return 0;
	}
	return 1;
}

#say isExtendedAscii("±");

sub isPrintableOrExtendedAscii {
	my @chars = map {ord($_)} split("", $_[0]);
	if (any {$_ < 32 || $_ == 127 || $_ > 255} @chars){
		return 0;
	}
	return 1;
}

#say isPrintableOrExtendedAscii(" sdfsf ±");
 
qq{
	0042 0065 006e 0020 0079 006f 006c 0063 0075 006c 0075 006b 0020 0075 0073 0074 0061 0073 0131 0079 0131 006d
	0048 0065 0072 0020 0067 0065 006d 0069 006e 0069 006e 0020 0074 0061 0079 0066 0061 0073 0131 0079 0131 006d
	0042 0065 006e 0069 006d 0020 0064 00fc 006e 0079 0061 006d 0020 006b 0075 015f 0062 0061 006b 0131 015f 0131
	0042 0065 006e 0020 0067 0065 006d 0069 006e 0069 006e 0020 006d 0061 0072 0074 0131 0073 0131 0079 0131 006d
	                                             0046 0065 0072 0068 0061 006e 0020 015e 0065 006e 0073 006f 0079
};