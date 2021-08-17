#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture run);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;

my $PATH;
my $help;
my $explanation = "This is an invoker script for directly running circos.\nThis is usually the case where you exit the primary script after the datatracks are created.\nIf you modify the files in ../datatracks and want to generate a new html file, you can use this script.\n";
my $version;
getopt();
defined $help ? print $explanation : print "" ;
defined $version ? print "version 1.0\n" : print "" ;


if ((defined $PATH)&&($PATH =~ /^.*\/.*\s*|^-.*\/.*\s*/)) {
	$PATH = $PATH;
	chomp $PATH;
} else {
	print "Please type the path or enter to skip to keep relative paths...\n";
	$_ = <STDIN>;
	chomp $_;
	$PATH = "-".$_;
	if ($PATH !~ /.*\/.*/) {
	$PATH = "..";
	}
}
my $PATH_domestic = $PATH;
$PATH_domestic =~ s/-//g;
if ($PATH_domestic eq "") {
	$PATH_domestic = "..";
}

my %degenerate_code = ("A" => ["GCT","GCC","GCA","GCG","Nonpolar"], "R" => ["CGT","CGC","CGA","CGG","AGA","AGG","Positive"], "N" => ["AAT","AAC","Polar"], "D" => ["GAT","GAC","Negative"], "C" => ["TGT","TGC","Polar"], "Q" => ["CAA","CAG","Polar"], "E" => ["GAA","GAG","Negative"], "G" => ["GGT","GGC","GGA","GGG","Nonpolar"], "H" => ["CAT","CAC","Positive"], "I" => ["ATT","ATC","ATA","Nonpolar"], "L" => ["TTA","TTG","CTT","CTC","CTA","CTG","Nonpolar"], "K" => ["AAA","AAG","Positive"], "M" => ["ATG","Nonpolar"], "F" => ["TTT","TTC","Aromatic"], "P" => ["CCT","CCC","CCA","CCG","Nonpolar"], "S" => ["TCT","TCC","TCA","TCG","AGT","AGC","Polar"], "T" => ["ACT","ACC","ACA","ACG","Polar"], "W" => ["TGG","Aromatic"], "Y" => ["TAT","TAC","Aromatic"], "V" => ["GTT","GTC","GTA","GTG","Nonpolar"], "X" => ["TAA","TGA","TAG","STOP"]);
my %aa_names = ("A" => "Alanine", "R" => "Arginine", "N" => "Asparagine", "D" => "Aspartic-Acid", "C" => "Cysteine", "Q" => "Glutamine", "E" => "Glutamic-Acid", "G" => "Glycine", "H" => "Histidine", "I" => "Isoleucine", "L" => "Leucine", "K" => "Lysine", "M" => "Methionine", "F" => "Phenylalanine", "P" => "Proline", "S" => "Serine", "T" => "Threonine", "W" => "Tryptophan", "Y" => "Tyrosine", "V" => "Valine", "X" => "STOP");

REENTER_FASTA:
print "Please enter the full name of your fasta file with the extention...[e.g fasta.txt]\n";
my $fasta = <STDIN>;
chomp $fasta;
open(my $fastafile, '<',"$PATH_domestic/circos-p/Input/$fasta") or goto REENTER_FASTA;
my @fasta_array = ();
while (<$fastafile>) {
	if ($_ =~ /.*[>]+.*/ || $_ =~ /.*[|.;]+.*/ || $_ !~ /^[ARNDBCQEZGHILKMFPSTWYVarndbcqezghilkmfpstwyv]+\s*$/) {
		} else {
		chomp $_;
		my @splitted = split ("",$_);
		push  (@fasta_array, @splitted);
	}
}
my $protein_code = join ("",@fasta_array);
print "Below is your protein code from fasta file:\n";
print $protein_code."\n";

REENTER_CDNA:
print "Type the cdna file name...[e.g mrna.txt]\n";
$_ = <STDIN>;
chomp $_;
my $cdnafilename = $_;
open(my $cdnafile, '<',"$PATH_domestic/circos-p/Input/$cdnafilename") or goto REENTER_CDNA;
my @cdna_array = ();
while (<$cdnafile>) {
	if ($_ =~ /.*[>]+.*/ || $_ =~ /.*[|.;]+.*/ || $_ !~ /^(\s*[ATCGatcg]+\s*)+$/) {
	} else {
		chomp $_;
		my @splitted = split ("",$_);
		foreach my $element (@splitted) {
			if ($element ne "") {
				$element =~ s/a/A/g;
				$element =~ s/t/T/g;
				$element =~ s/c/C/g;
				$element =~ s/g/G/g;
				if ($element =~ /^\s*$/) {
				} else {
				push  (@cdna_array, $element);
				}
			}
		}
	}
}
my @cdna_translated_candidates;
for (my $i = 0; $i < 3;$i++) {
	no warnings;
	my $translated = "";
	my $j = 0;
	until ($i+2+$j > $#cdna_array) {
		my $codon = $cdna_array[$i+$j].$cdna_array[$i+1+$j].$cdna_array[$i+2+$j];
		#my $amino_acid = grep {@{$degenerate_code{$_}}[0..($#{$degenerate_code{$_}}-1)] eq $codon} ("A", "R", "N", "D", "C", "Q", "E", "G", "H", "I", "L", "K", "M", "F", "P", "S", "T", "W", "Y", "V", "X");
		my @amino_acid = grep {$codon ~~ @{$degenerate_code{$_}}[0..($#{$degenerate_code{$_}}-1)]} keys %degenerate_code;
		$translated = $translated.$amino_acid[0];
		$j += 3;
	}
	push (@cdna_translated_candidates,$translated);
}
#print $cdna_translated_candidates[0]."\n";
#print $cdna_translated_candidates[1]."\n";
#print $cdna_translated_candidates[2]."\n";
my $shift_count;
my $pop_count;
if ($cdna_translated_candidates[0] eq $protein_code) {
	print "Your cDNA exactly matches your fasta file.Continuing...\n";
	$shift_count = 0;
	$pop_count = 0;
} elsif ($cdna_translated_candidates[0] =~ /$protein_code/) {
	my @splitted = split ("$protein_code",$cdna_translated_candidates[0]);
	print $splitted[0]."\n";
	print $splitted[1]."\n";
	my @shift_count_array = split ("",$splitted[0]);
	$shift_count = 0 + 3*scalar(@shift_count_array);
	$pop_count = scalar (@cdna_array) - 3*scalar (@fasta_array) - $shift_count;
	print "Matched the fasta code within frame 1...\n";
} elsif ($cdna_translated_candidates[1] =~ /$protein_code/) {
	my @splitted = split ("$protein_code",$cdna_translated_candidates[1]);
	my @shift_count_array = split ("",$splitted[0]);
	$shift_count = 1 + 3*scalar(@shift_count_array);
	$pop_count = scalar (@cdna_array) - 3*scalar (@fasta_array) - $shift_count;
	print "Matched the fasta code within frame 2...\n";
} elsif ($cdna_translated_candidates[2] =~ /$protein_code/) {
	my @splitted = split ("$protein_code",$cdna_translated_candidates[2]);
	my @shift_count_array = split ("",$splitted[0]);
	$shift_count = 2 + 3*scalar(@shift_count_array);
	$pop_count = scalar (@cdna_array) - 3*scalar (@fasta_array) - $shift_count;
	print "Matched the fasta code within frame 3...\n";
} else {
	print "There is a problem with your cDNA file, cannot match to fasta!\n";
}
for (my $i = 0;$i < $shift_count;$i++) {
	shift (@cdna_array);
} 
for (my $i = 0;$i < $pop_count;$i++) {
	pop (@cdna_array);
} 
print scalar (@cdna_array)."\n";
my $protein_length;
if (scalar(@cdna_array) % 3 != 0) {
	print "There is a problem with the cDNA file, number of bases is not multiple of 3...\n";
	exit;
} elsif (scalar(@fasta_array)*3 == scalar (@cdna_array)) {
	print "Your cdna file is ok and in phase with the fasta file...\n";
	$protein_length = scalar(@cdna_array)/3;
} else {
	print "Your cdna and fasta data is not in phase!..\n";
	exit;
}


my $markup_choice;
print "Were there any markups in your file?[y/n]\n";
$markup_choice = <STDIN>;
chomp $markup_choice;
my $protein_name;
print "Write the name of your protein please..[ex: EGFR]\n";
$protein_name = <STDIN>;
chomp $protein_name;


#Run circos
print "Running circos..\n";
my $circos = "C:/strawberry/circos-0.67-7/bin/circos";
my $circos_results = system($^X, $circos, "-conf=../circos-p/templates/circos_template.conf", "-outputdir=../circos-p/Output");
print "Your image is created..\n";
#Run circos

#Inject javascript
print "Injecting Javascript..\n";
copy("$PATH_domestic/circos-p/Output/circos.svg", "$PATH_domestic/circos-p/Output/circos.txt") or die "$!\n";
my $javascriptfile;
if ($markup_choice =~ /y.*/i) {
	open($javascriptfile, '<',"$PATH_domestic/circos-p/templates/javascript.txt") or die "Cannot read from javascript template!\n";
} else {
	open($javascriptfile, '<',"$PATH_domestic/circos-p/templates/javascript_noconnector.txt") or die "Cannot read from javascript template!\n";
}
open(my $svgtextfile, '<',"$PATH_domestic/circos-p/Output/circos.txt") or die "Cannot read from vector file!\n";
open(my $htmltextfile, '>',"$PATH_domestic/circos-p/Output/$protein_name.txt") or die "Cannot write to html text file!\n";

while (<$javascriptfile>) {
	my $i = 0;
	if ($_ =~ /var cdna/) {
		print $htmltextfile "var cdna = ".arrayToString(@cdna_array).";\n";
	} else {
		print $htmltextfile $_;
	}
	if ($_ =~ /<body>/) {
		while (<$svgtextfile>) {
			if (($i == 0) || ($i == 1)) {
			} elsif ($i == 2) {
				$_ =~ s/<svg width="6000px" height="6000px"/<svg id="master" preserveAspectRatio="xMidYMid" viewBox ="-500 0 7000 6000"/;
				print $htmltextfile $_;
			} else {
				print $htmltextfile $_;
			}
			$i++;
		}
	}
}
open($htmltextfile, '<',"$PATH_domestic/circos-p/Output/$protein_name.txt") or die "Cannot read from html text!\n";
copy ($htmltextfile, "$PATH_domestic/circos-p/Output/$protein_name.html") or die "$!\n";
#Inject javascript

print "Your file $protein_name.html is created under ../circos-p/Output folder..\n";


sub skip_header {
  my $FH = shift;
  <$FH>;
}


sub take_min {
my @min;
my @test_set;
@test_set = @_;
my $i = 0;
push (@min, $test_set[$i]);
$i++;
until ($i == scalar(@test_set)) {
#below if statement makes sure that whathever thats pushed in the array is a number but not an empty space.
	if ($test_set[$i] !~ /^\s*$/) {
		if ($test_set[$i]<$min[0]) {
			shift (@min);
			push (@min, $test_set[$i]);
		} else {
		}
	}
	$i++;
}
return $min[0];
#Uncomment below to test your array
#print "your min value for the test is $min[0]!\n";
}

sub take_max {
my @max;
my @test_set;
@test_set = @_;
my $i = 0;
push (@max, $test_set[$i]);
$i++;
until ($i == scalar(@test_set)) {
	if ($test_set[$i] !~ /^\s*$/) {
		if ($test_set[$i]>$max[0]){
			shift (@max);
			push (@max, $test_set[$i]);
		} else {
		}
	}
	$i++;
}
return $max[0];
#Uncomment below to test your array
#print "your max value for the test is $max[0]!\n";
}

sub getopt {
#Use the getoptions module.
GetOptions ("help=s" => \$help, "version=s" => \$version, "path=s" => \$PATH) or die ("Once you enter argument press a key and enter to make sure they are defined.\n[Ex: --help h --version v]\n");
}

sub arrayToString {
	my @array = @_;
	my $string = "";
	for (my $i = 1;$i<=scalar(@array);$i++) {
		if ($i == 1) {
			$string = $string."[\"".$array[$i-1]."\",";
		} elsif ($i == scalar(@array)) {
			$string = $string."\"".$array[$i-1]."\"]";
		} elsif ($i % 100 == 0) {
			$string = $string."\"".$array[$i-1]."\",\n";
		} else {
			$string = $string."\"".$array[$i-1]."\",";
		}
	}
	return $string;
}