#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture run);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;

my $PATH;
my $help;
my $explanation = "This script will change your variation style from > to / separated.\nEither supply the input into the input folder or specify path\nProvide a SINGLE column of variations.\n";
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
my $protein_name;
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

REENTER_INPUT:
print "Enter the name of your input file......[e.g file.txt]\n";
my $inputFileName = <STDIN>;
chomp $inputFileName;
open(my $inputfile, '<',"$PATH_domestic/circos-p/Input/$inputFileName") or goto REENTER_INPUT;


print "Enter the name for your output file......[e.g outputFile.txt]\n";
my $outputFileName = <STDIN>;
chomp $outputFileName;
open(my $outputfile, '>',"$PATH_domestic/circos-p/Input/$outputFileName") or die "Cannot write to file!\n";

my $lineNumber = 0;
while(<$inputfile>) {
	$lineNumber++;
	my $eachLine = $_;
	chomp $eachLine;
	if ($eachLine =~ /\+|-/gi) {
		print "found a splice mutation at $lineNumber:\n".$eachLine."\nPress enter to skip..\n";
		<STDIN>;
		next;
	}
	$eachLine =~ /([1-9][0-9]*_?[1-9][0-9]*)(del|ins|dup)?([a-z]+)?>?([a-z]+)?/gi;
	my $coding = $1;
	my $delOrIns = $2;
	$delOrIns = !defined $delOrIns ? "undef" : $delOrIns;
	my $from = $3;
	my $to = $4;
	my @codingArray = split("_",$coding);
	my $type = $#codingArray == 0 ? "SNV" : "del/ins/delins";
	#print "Line $lineNumber lastIndexOfCodingArray and type are: ".$#codingArray." and $type\n";
	my $strand;
	if ($type eq "SNV" && $codingArray[0]<=$#cdna_array) {
		my $start = take_min(@codingArray);
		my $fromReverse = reverse_sub($from);
		if ($cdna_array[$start-1] =~ /$from/i) {
			$strand = "1";
		} elsif ($cdna_array[$start-1] =~ /$fromReverse/i) {
			$strand = "-1";
		} else {
			print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a SNV. However the cdna file at pos $start reads ".$cdna_array[$start-1]."\nThis does not match the reverse either. Please press enter to skip..\n";
			<STDIN>;
			next;
		}
		print $outputfile $strand."\t".$from."/".$to."\t".$start."\n";
	} elsif ($type eq "del/ins/delins" && $codingArray[0]<=$#cdna_array) {
		if ($delOrIns eq "del" || $delOrIns eq "undef") {
			if ($codingArray[0]<$codingArray[1]) {
				$strand = "1";
				my $start = $codingArray[0];
				my $end = $codingArray[1];
				my $query = "";
				for (my $i = $codingArray[0]-1;$i<take_min($codingArray[1],scalar(@cdna_array));$i++) {
					$query = $query.$cdna_array[$i];
				}
				if (!defined $from) {
					$from = $query;
				}
				if ($from !~ /$query/gi && $query !~ /$from/) {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a deletion in FORWARD direction.\nHowever the cdna file between pos $start and $end reads ".$query."\nMeanwhile this does not match what is said to be deleted:\n$from\nPlease press enter to skip..\n";
					<STDIN>;
					next;
				} elsif (abs(length($from)-length($query))/take_min(length($from),length($query)) >= 0.5) {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a deletion in FORWARD direction.\nHowever the length of the cdna between pos $start and $end is ".length($query)."\nPlease beware that this does not match the length of what is said to be deleted:\n".length($from)."\nAlthough the sequences do partially match,\nThere more than or equal to 50 percent difference in length.\nPlease press enter to skip..\n";
					<STDIN>;
					next;
				} elsif (length($from) != length($query)) {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a deletion in FORWARD direction.\nHowever the length of the cdna between pos $start and $end is ".length($query)."\nPlease beware that this does not match the length of what is said to be deleted:\n".length($from)."\nHowever the sequences do partially match, so it will be processed.\nPlease press enter to continue..\n";
					<STDIN>;
				} 
				if (!defined $to) {
					$to = "-";
				}
				print $outputfile $strand."\t".$from."/".$to."\t".$start."\n";
			} elsif ($codingArray[0]>$codingArray[1]) {
				$strand = "-1";
				my $start = $codingArray[1];
				my $end = $codingArray[0];
				my $query = "";
				for (my $i = $codingArray[1]-1;$i<take_min($codingArray[0],scalar(@cdna_array));$i++) {
					$query = $query.$cdna_array[$i];
				}
				if (!defined $from) {
					$from = $query;
				}
				my $fromReverse = reverse_sub($from);
				if ($fromReverse !~ /$query/gi && $query !~ /$fromReverse/) {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a deletion in REVERSE direction.\nHowever the cdna file between pos $start and $end reads ".$query."\nMeanwhile this does not match what is said to be deleted:\n$fromReverse\nPlease press enter to skip..\n";
					<STDIN>;
					next;
				} elsif (abs(length($fromReverse)-length($query))/take_min(length($fromReverse),length($query)) >= 0.5) {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a deletion in REVERSE direction.\nHowever the length of the cdna between pos $start and $end is ".length($query)."\nPlease beware that this does not match the length of what is said to be deleted:\n".length($fromReverse)."\nAlthough the sequences do partially match,\nThere more than or equal to 50 percent difference in length.\nPlease press enter to skip..\n";
					<STDIN>;
					next;
				} elsif (length($fromReverse) != length($query)) {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a deletion in REVERSE direction.\nHowever the length of the cdna between pos $start and $end is ".length($query)."\nPlease beware that this does not match the length of what is said to be deleted:\n".length($fromReverse)."\nHowever the sequences do partially match, so it will be processed.\nPlease press enter to continue..\n";
					<STDIN>;
				}
				if (!defined $to) {
					$to = "-";
				}
				print $outputfile $strand."\t".$from."/".$to."\t".$start."\n";
			} elsif ($codingArray[0] == $codingArray[1]) {
				my $start = $codingArray[0];
				my $query = "";
				for (my $i = $codingArray[0]-1;$i<$codingArray[1];$i++) {
					$query = $query.$cdna_array[$i];
				}
				if (!defined $from) {
					$from = $query;
				}
				my $fromReverse = reverse_sub($from);
				if (!defined $to) {
					$to = "-";
				}
				if ($from =~ /$query/) {
					$strand = "1";
					print $outputfile $strand."\t".$from."/".$to."\t".$start."\n";
				} elsif ($fromReverse =~ /$query/) {
					$strand = "-1";
					print $outputfile $strand."\t".$from."/".$to."\t".$start."\n";
				} else {
					print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a SINGLE basepair deletion.\nHowever what is deleted (".$from.") does not match neither mRNA (".$query.") nor reverse of it (".reverse_sub($query).").\nPlease press enter to skip..\n";
					<STDIN>;
					next;
				}
			} else {
				print "An unknown error occured at line $lineNumber:\n".$eachLine."\nPlease press enter to skip..\n";
				<STDIN>;
				next;
			}
		} elsif ($delOrIns eq "ins") {
			$strand = "1";
			my $start = take_min(@codingArray);
			if (!defined $from || $from !~ /^\s*[a-z]+\s*$/gi) {
				print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as an insertion.\nHowever what is inserted is either NOT defined or not a sequence.\nPlease press enter to skip..\n";
				<STDIN>;
				next;
			}
			print $outputfile $strand."\t"."-"."/".$from."\t".$start."\n";
		} elsif ($delOrIns eq "dup") {
			$strand = "1";
			my $start = take_min(@codingArray);
			my $end = take_max(@codingArray);
			if (!defined $from || $from !~ /^\s*[a-z]+\s*$/gi) {
				print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as an insertion.\nHowever what is inserted is either NOT defined or not a sequence.\nPlease press enter to skip..\n";
				<STDIN>;
				next;
			}
			my $query = "";
			for (my $i = $codingArray[0]-1;$i<take_min($codingArray[1],scalar(@cdna_array));$i++) {
				$query = $query.$cdna_array[$i];
			}
			if ($from !~ /$query/gi && $query !~ /$from/) {
				print "Please take a look at the following line $lineNumber:\n".$eachLine."\nThis is classified as a duplication.\nHowever the cdna file between pos $start and $end reads ".$query."\nMeanwhile this does not match what is said to be deleted:\n$from\nPlease press enter to skip..\n";
				<STDIN>;
				next;
			}
			print $outputfile $strand."\t"."-"."/".$from."\t".$end."\n";
		}
	} else {
		print "An unknown error occured at line $lineNumber:\n".$eachLine."\nPlease press enter to skip..\n";
		<STDIN>;
		next;
	}
}
print "End of file is reached. Your output is created.\nAdd the required fields and supply it to I-PV as input.\n";





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

sub reverse_sub {
	my $string = $_[0];
	$string =~ tr/atcgATCG/tagcTAGC/;
	my @stringArray = split("",$string);
	my @reverseArray;
	for (my $i =0;$i<scalar(@stringArray);$i++) {
		unshift(@reverseArray,$stringArray[$i]);
	}
	my $reverseString = join ("",@reverseArray);
	return $reverseString;
}