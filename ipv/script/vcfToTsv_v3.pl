#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture run);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;

my $PATH;
my $help;
my $explanation = "This program will convert your vcf to tsv(tab separated values) and filter from unwanted transcripts.\nYour file will be located in the ..\\Input folder..\n";
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

my $vcf_name;
REENTER_VCF:
print "Please provide the name of the VCF file...[e.g SNVindels.txt]\n";
$_ = <STDIN>;
chomp $_;
$vcf_name = $_;
open(my $vcffile, '<',"$PATH_domestic/circos-p/Input/$vcf_name") or goto REENTER_VCF;
print "Should we skip the header?\n";
my $answer = <STDIN>;
chomp $answer;
my $header = "";
if ($answer =~ /y.*/) {
	print "How many times should the header be skipped?\n";
	my $header_skip_times = <STDIN>;
	chomp $header_skip_times;
	my $skip_count = 0;
	until ($skip_count == $header_skip_times) {
		print "Skipping header...\n";
		skip_header($vcffile);
		$skip_count++;
	}
} else {
	print "The header will NOT be skipped...\n";
}
print "Do you want to keep your old header?[y/n]";
my $old_header = <STDIN>;
chomp $old_header;


print "What is the original separator of the data? (tabs, spaces, semicolons etc...)\n[Hint: If the spaces in the file is irregular, write whitespace.]\n";
my $separator = <STDIN>;
chomp $separator;
print "You will be asked several questions below regarding variant information.\nYou are required to enter an integer only which corresponds to a column number.\nFirst column is numbered 1, second 2 and so on..\nPress any key and enter to continue\n";
my $emtpty_response = <STDIN>;
print "Which column do you have the reference sequence?\n[Hint: It is the column where the ancesteral allele base(s) are written(eg.A, CTA..)]\n";
my $basechange_number = <STDIN>;
chomp $basechange_number;
$basechange_number -= 1;
print "Which column do you have the variant sequence?\n[Hint: It is the column where the variant allele base(s) are written(eg.A, CTA..)]\n";
my $basechange_number_2 = <STDIN>;
chomp $basechange_number_2;
$basechange_number_2 -= 1;
print "Which column do you have the type of substitution?\nIf you do not have a type set, you can also enter the previously given reference base column.\nThis feature is not yet implemented in i-PV so it will not be printed..\n";
my $substitiontype_number = <STDIN>;
chomp $substitiontype_number;
$substitiontype_number -= 1;
print "Which column do you have the substitution coordinates?\nYou can supply any column that include data like c.A234T etc.\n[Hint: Choose the Coding Start column.]\n";
my $substitioncoordinates_number = <STDIN>;
chomp $substitioncoordinates_number;
$substitioncoordinates_number -= 1;
print "Which column do you have the validation status?\nIf not applicapable, use 'setTo' keyword to set a column. Acceptable values are 'Validated', 'Not_Validated' or 'N/A'.\nEtc. 'setTo N/A' (without quotes) sets a column of N/A..\n";
my $validationstatus_number = <STDIN>;
chomp $validationstatus_number;
if ($validationstatus_number !~ /setTo/) {
	$validationstatus_number -= 1;
}
print "Which column do you have the strand of the change?\n[Hint: This is the column where indicates + or - or 1 or -1 for the strand.\nIf this column does not exist use setTo keyword to set a column.\nEtc. 'setTo 1' (without quotes) sets a strand column of 1.\nIf you have no idea about strand information try 'setTo 1' first..\n";
my $strand_number = <STDIN>;
chomp $strand_number;
if ($strand_number !~ /setTo/) {
	$strand_number -= 1;
}
print "Which stand is your gene located in?\n[Hint: You can check this from publicly available genome browsers.\nYou can enter plus,positive,+,1 or inverse of these parameters.]\n";
my $gene_location = <STDIN>;
chomp $gene_location;
print "Please enter your transcript ID [e.g ENGXXXXXXXX,NM_YYYYYY. ].\n[Hint: Write 'ProcessAll' to skip transcript filtering..]\n";
my $transcript_ID = <STDIN>;
my $transcript_ID_column;
chomp $transcript_ID;
if ($transcript_ID =~ /ProcessAll/) {
	$transcript_ID_column = "N/A";
} else {
	print "Please enter in which column your transcript IDs are located in\n";
	$transcript_ID_column = <STDIN>;
	$transcript_ID_column -= 1;
}

###PREDICTIONS###
my $polyphen2;
RETRY_POLYPHEN2:
print "Which column do you have the polyphen2 scores?\n[Hint: Choose the polyphen2 score column. If not available write enter 'NA']\n";
$polyphen2 = <STDIN>;
chomp $polyphen2;
if ($polyphen2 !~ /^[1-9]+[0-9]*$|^na$/i) {
	goto RETRY_POLYPHEN2;
} elsif ($polyphen2 =~ /^[1-9]+[0-9]*$/) {
	$polyphen2 -= 1;
}
my $sift;
RETRY_SIFT:
print "Which column do you have the sift scores?\n[Hint: Choose the sift score column. If not available write enter 'NA']\n";
$sift = <STDIN>;
chomp $sift;
if ($sift !~ /^[1-9]+[0-9]*$|^na$/i) {
	goto RETRY_SIFT;
} elsif ($sift =~ /^[1-9]+[0-9]*$/) {
	$sift -= 1;
}
###PREDICTIONS###

print "Converting to tsv...\n";

###OPEN FILE AND PRINT HEADER(S)###
open(my $convertedTsv, '>',"$PATH_domestic/circos-p/Input/converted.txt") or die "Cannot open for writing to file!\n";
if ($old_header =~ /^y.*/i) {
	print $convertedTsv $header;
}
print $convertedTsv "Variant Alleles"."\t"."Coding Start"."\t"."Validation Status"."\t"."Strand"."\t"."Gene Location(Transcript Strand)"."\t"."TranscriptID"."\t"."polyphen2"."\t"."sift"."\t"."rsID"."\t"."Variation Source"."\n";
###OPEN FILE AND PRINT HEADER(S)###

while (<$vcffile>) {
	chomp;
	my @each_line =  separator ($_);
	my @vcf_data = ();
	###PREDICTIONS###
	my %prediction_data = fetch_predictions(\@each_line);
	###PREDICTIONS###
	
	###MERGE REFERENCE AND VARIANT ALLELES###
	my $Ref = $each_line[$basechange_number];
	my $Var = $each_line[$basechange_number_2];
	$Var =~ s/[,;:\\]/\//g;
	my $mergeRefVar = $Ref."/".$Var;
	push (@vcf_data, $mergeRefVar);
	###MERGE REFERENCE AND VARIANT ALLELES###
	
	push (@vcf_data, $each_line[$substitiontype_number]);
	
	###EXTRACT CODING START###
	my $extractedCodingStart;
	if ($each_line[$substitioncoordinates_number] =~ /^\s*[0-9]+\s*$/) {
		$extractedCodingStart = $each_line[$substitioncoordinates_number];
		$extractedCodingStart =~ s/\s*//gi;
	} elsif ($each_line[$substitioncoordinates_number] =~ /(c\.[^+\-*]?(A|T|C|G)?[0-9]+[^+\-*]?)(\w*\d*\s*[.:,;<>]*)*/i) {
		if($each_line[$substitioncoordinates_number] =~ /$1[\-+]/i) {
			next;
		}
		$extractedCodingStart = $1;
		$extractedCodingStart =~ s/c|\.|A|T|C|G|[<>_]|\s*//gi;
	} else {
		next;
	} 
	push (@vcf_data, $extractedCodingStart);
	###EXTRACT CODING START###
	
	###SET VALIDATION STATUS###
	my $validationStatus;
	if($validationstatus_number =~ /setTo/) {
		$validationStatus = $validationstatus_number;
		$validationStatus =~ s/\s*|setTo//g;
	} else {
		$validationStatus = $each_line[$validationstatus_number];
	}
	push (@vcf_data, $validationStatus);
	###SET VALIDATION STATUS###
	
	###SET STRAND###
	my $strand;
	if($strand_number =~ /setTo/) {
		$strand = $strand_number;
		$strand =~ s/\s*|setTo//g;
	} else {
		$strand = $each_line[$strand_number];
	}
	push (@vcf_data, $strand);
	###SET STRAND###
	
	#Look inside the file for rsID
	for (my $i = 0;$i <= $#each_line;$i++) {
		if ($each_line[$i] =~ /rs[0-9]+/ ) {
			push(@vcf_data, $each_line[$i]);
			last;
		}
		if ($i == $#each_line) {
			#If no rsID is found a NotAvailable string pushed instead
			push (@vcf_data, "rsID_NotAvailable");
		}
	}
	#Look for variation source in the file
	for (my $i = 0;$i <= $#each_line;$i++) {
		if ($each_line[$i] =~ /dbsnp|clinvar|hgmd|phencode|customdb|^esp$|^\s*human\s*core\s*exome/i ) {
			push(@vcf_data, $each_line[$i]);
			last;
		}
		if ($i == $#each_line) {
			#If no source is found than push a string instead
			push (@vcf_data, "source_NotAvailable");
		}
	}
	if ($transcript_ID !~ /ProcessAll/) {
		if ($each_line[$transcript_ID_column] !~ /$transcript_ID/) {
			#You can turn on the below warning if you want but it might flod the screen with some inputs that contain a lot of transcripts.
			#print "Transcript filtered based on choice..\n";
			next;
		}
	}
	if (!defined $vcf_data[2]){
		#I wanted to include the below warning however it really dominates the screen..
		#print "Encountered empty coding start. Must have been in an intron. Skipping..\n";
		next;
	}
	print $convertedTsv $vcf_data[0]."\t".$vcf_data[2]."\t".$vcf_data[3]."\t".$vcf_data[4]."\t".$gene_location."\t".$transcript_ID."\t".$prediction_data{"polyphen2"}."\t".$prediction_data{"sift"}."\t".$vcf_data[5]."\t".$vcf_data[6]."\n";
}
print "CONVERSION::OK\n";


print "Your converted tsv file is created under ../circos-p/Input folder.\nSupply this to i-PV as input..\n";


sub separator {
my $ref = $_[0];
my @array;
	if ($separator =~ /^tab.*/) {
		@array = split (/\t/, $ref);
	} elsif ($separator =~ /^spac.*/) {
		@array = split (/\s/, $ref);
	} elsif ($separator =~ /^semi.*/) {
		@array = split (/;/, $ref);
	} elsif ($separator =~ /^white.*/) {
		@array = split (/\s+/, $ref);
	} else {
		print "The separator of your choice was undefined. Please enter the character itself...\n";
		my $undef_separator = <STDIN>;
		chomp $undef_separator;
		print "The character $undef_separator will be used as separator...\n";
		@array = split ("$undef_separator", $ref);
	}
return @array;
}


sub skip_header {
  my $FH = shift;
  $header = $header.<$FH>;
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

sub fetch_predictions {
	my @each_line = @{$_[0]};
	my %hash = ("polyphen2" => "NA", "sift" => "NA");
	foreach my $element (keys %hash) {
		if ((eval("\$".$element) =~ /^[1-9]+[0-9]*$/) && (defined $each_line[eval("\$".$element)]) && ($each_line[eval("\$".$element)] !~ /^\s*\t*$/)) {
			$hash{$element} = $each_line[eval("\$".$element)];
		}
	}
	return %hash;
}