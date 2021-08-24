#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture run);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;
use FindBin;

my $PATH;
my $help;
my $explanation = "Colors: Colors can be prefixed by 1 or 2 v's (stands for very) followed by l (light) or d (dark) and then root, all in small letters.\nThese are the root color names:\nRed, blue, green, yellow, orange, grey, purple\nMagenta, brown, cyan\nCrimson, warmchampagne, ashlight, firelight, angelica.\nInvoking Circos: Make sure that the path specified in line 843 directs to the correct location.\nOtherwise circos will not be invoked.\n";
my $version;
getopt();
defined $help ? print $explanation : print "" ;
defined $version ? print "version 1.46\n" : print "" ;


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

my $domain_count = 0;
my @domains;
my @domain_properties;
my %domain_colors;
list_creation();


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



print "What is the name of your protein?[e.g BRCA1]\n";
$_ = <STDIN>;
chomp $_;
$protein_name = $_;
open(my $karyotypefile, '>',"$PATH_domestic/circos-p/datatracks/karyotype.txt") or die "Cannot open the karyotype file!\n";
print "Making karyotype file...\n";
print $karyotypefile "chr - ".$protein_name." ".$protein_name." "."0"." ".$protein_length."000000"." "."vdgrey"."\n";
print "KARYOTYPE::OK\n";



#my %degenerate_code = ("A" => ["GCT","GCC","GCA","GCG","Nonpolar"], "R" => ["CGT","CGC","CGA","CGG","AGA","AGG","Positive"], "N" => ["AAT","AAC","Polar"], "D" => ["GAT","GAC","Negative"], "C" => ["TGT","TGC","Polar"], "Q" => ["CAA","CAG","Polar"], "E" => ["GAA","GAG","Negative"], "G" => ["GGT","GGC","GGA","GGG","Nonpolar"], "H" => ["CAT","CAC","Positive"], "I" => ["ATT","ATC","ATA","Nonpolar"], "L" => ["TTA","TTG","CTT","CTC","CTA","CTG","Nonpolar"], "K" => ["AAA","AAG","Positive"], "M" => ["ATG","Nonpolar"], "F" => ["TTT","TTC","Aromatic"], "P" => ["CCT","CCC","CCA","CCG","Polar"], "S" => ["TCT","TCC","TCA","TCG","AGT","AGC","Polar"], "T" => ["ACT","ACC","ACA","ACG","Polar"], "W" => ["TGG","Aromatic"], "Y" => ["TAT","TAC","Aromatic"], "V" => ["GTT","GTC","GTA","GTG","Nonpolar"], "X" => ["TAA","TGA","TAG","STOP"]);



print "Making protein sequence and scatter plots...\n";
open(my $sequencefile, '>',"$PATH_domestic/circos-p/datatracks/protein_sequence.txt") or die "Cannot open the sequence file!\n";
open(my $scatterfile, '>',"$PATH_domestic/circos-p/datatracks/scatter.txt") or die "Cannot open the scatter file!\n";
for (my $i = 0;$i < scalar (@fasta_array);$i++) {
	my $type;
	foreach my $keys (keys %degenerate_code) {
		if ($keys eq $fasta_array[$i]) {
			$type = ${$degenerate_code{$keys}}[$#{$degenerate_code{$keys}}]
		}
	}
	print $sequencefile $protein_name." ".$i*1000000 ." ".($i+1)*1000000 ." ".$fasta_array[$i] ." "."type=".$type.","."scatterValue=".($i % 3)*0.5 .","."svgid="."seq_".$aa_names{$fasta_array[$i]}."_".($i+1).","."svgclass=sequence"."\n";
	print $scatterfile $protein_name." ".$i*1000000 ." ".($i+1)*1000000 ." ".($i % 3)*0.5 ." "."type=".$type.","."scatterValue=".($i % 3)*0.5 .","."svgid="."scat_".$type."_Residue_".($i+1).","."svgclass=scatter"."\n";
}
print "SEQUENCE PLOT::OK\n";
print "SCATTER PLOT::OK\n";


my $snp_name;
REENTER_SNP:
print "Please provide the name of the SNP file...[e.g SNP.txt]\n";
$_ = <STDIN>;
chomp $_;
$snp_name = $_;
open(my $snpfile, '<',"$PATH_domestic/circos-p/Input/$snp_name") or goto REENTER_SNP;
print "Should we skip the header?\n";
my $answer = <STDIN>;
chomp $answer;
if ($answer =~ /y.*/) {
	print "How many times should the header be skipped?\n";
	my $header_skip_times = <STDIN>;
	chomp $header_skip_times;
	my $skip_count = 0;
	until ($skip_count == $header_skip_times) {
		print "Skipping header...\n";
		skip_header($snpfile);
		$skip_count++;
	}
} else {
	print "The header will NOT be skipped...\n";
}


print "What is the original separator of the data? (tabs, spaces, semicolons etc...)\n[Hint: If the spaces in the file is irregular, write whitespace.]\n";
my $separator = <STDIN>;
chomp $separator;
print "You will be asked several questions below regarding SNP information.\nYou are required to enter an integer only which corresponds to a column number.\nFirst column is numbered 1, second 2 and so on..\nPress any key and enter to continue\n";
my $emtpty_response = <STDIN>;
print "Which column do you have the change in bases?\n[Hint: It is the column where the ancesteral and alternative alleles are separated by a forward slash(eg.A/G,C/T/A..)]\n";
my $basechange_number = <STDIN>;
chomp $basechange_number;
$basechange_number -= 1;
print "Which column do you have the type of substitution?\nIf you do not have a type set, you can also enter the previously given base change column.\n";
my $substitiontype_number = <STDIN>;
chomp $substitiontype_number;
$substitiontype_number -= 1;
print "Which column do you have the substitution coordinates?\n[Hint: Choose the Coding Start column.]\n";
my $substitioncoordinates_number = <STDIN>;
chomp $substitioncoordinates_number;
$substitioncoordinates_number -= 1;
print "Which column do you have the validation status?\nIf not applicapable, enter the same column as base change, the column where writes A/G,C/T/A etc..\n";
my $validationstatus_number = <STDIN>;
chomp $validationstatus_number;
$validationstatus_number -= 1;
print "Which column do you have the strand of the change?\n[Hint: This is the column where indicates + or - or 1 or -1 for the strand.]\n";
my $strand_number = <STDIN>;
chomp $strand_number;
$strand_number -= 1;
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

###EXTRACT MAF###
my $maf;
RETRY_MAF:
print "Which column do you have the MAF(minor allele frequency)?\n[Hint: This is a value between 0 and 1. If not available write enter 'NA']\n";
$maf = <STDIN>;
chomp $maf;
if ($maf !~ /^[1-9]+[0-9]*$|^na$/i) {
	goto RETRY_MAF;
} elsif ($maf =~ /^[1-9]+[0-9]*$/) {
	$maf -= 1;
}
###EXTRACT MAF###

print "Making missense SNP text plot...\n";
my @SNPtextplot_inventory;
my $missense_counter = 0;
my %reversebase = ("A" => "T", "T" => "A", "C" => "G", "G" => "C");
open(my $snpfile_missense_textplot, '>',"$PATH_domestic/circos-p/datatracks/text_plot_missense.txt") or die "Cannot open the text plot file!\n";
while (<$snpfile>) {
	chomp;
	my @each_line =  separator ($_);
	my @snp_data = ();
	###PREDICTIONS###
	my %prediction_data = fetch_predictions(\@each_line);
	###PREDICTIONS###
	###MAF###
	my $ipvMAF;
	if (($maf =~ /^[1-9]+[0-9]*$/) && (defined $each_line[$maf]) && ($each_line[$maf] !~ /^\s*\t*$/)) {
		$ipvMAF = $each_line[$maf];
	} else {
		$ipvMAF = "NA";
	}
	###MAF###
	push (@snp_data, $each_line[$basechange_number]);
	push (@snp_data, $each_line[$substitiontype_number]);
	push (@snp_data, $each_line[$substitioncoordinates_number]);
	push (@snp_data, $each_line[$validationstatus_number]);
	push (@snp_data, $each_line[$strand_number]);
	#Look inside the file for rsID
	for (my $i = 0;$i <= $#each_line;$i++) {
		if ($each_line[$i] =~ /rs[0-9]+/ ) {
			push(@snp_data, $each_line[$i]);
			last;
		}
		if ($i == $#each_line) {
			#If no rsID is found a NotAvailable string pushed instead
			push (@snp_data, "rsID_NotAvailable");
		}
	}
	#Look for variation source in the file
	for (my $i = 0;$i <= $#each_line;$i++) {
		if ($each_line[$i] =~ /dbsnp|clinvar|hgmd|phencode|customdb|^esp$|^\s*human\s*core\s*exome/i ) {
			push(@snp_data, $each_line[$i]);
			last;
		}
		if ($i == $#each_line) {
			#If no source is found than push a string instead
			push (@snp_data, "source_NotAvailable");
		}
	}
	if ($transcript_ID !~ /ProcessAll/) {
		if ($each_line[$transcript_ID_column] !~ /$transcript_ID/) {
			#You can turn on the below warning if you want but it might flod the screen with some inputs that contain a lot of transcripts.
			#print "Transcript filtered based on choice..\n";
			next;
		}
	}
	if (!defined $snp_data[2]){
		#I wanted to include the below warning however it really dominates the screen..
		#print "Encountered empty coding start. Must have been in an intron. Skipping..\n";
		next;
	}
	my $SNPtextplot_inventory_element = "";
	#print "Short circuit check!\n";
	for (my $i = 0;$i<=$#snp_data;$i++){
		$SNPtextplot_inventory_element = $SNPtextplot_inventory_element.$snp_data[$i];
	}
	#Smartmatch is experimental in newer versions of Perl so I decided to write something equivalent to it
	#if($SNPtextplot_inventory_element ~~ @SNPtextplot_inventory){
	if(grep {$SNPtextplot_inventory[$_] =~ $SNPtextplot_inventory_element} (0..$#SNPtextplot_inventory)){
		print "Duplicate line detected. Skipping this mutation...\n";
		next;
	}
	#print "Short circuit check!\n";
	my $validation_status;
	if ($snp_data[3] =~ /^y.*/) {
		 $validation_status = "Validated";
	} elsif ($snp_data[3] =~ /^n.*/) {
		$validation_status = "Not_Validated";
	} else {
		$validation_status = "N/A";
	}
	if ((($snp_data[1] =~ /subst/)||($snp_data[1] =~ /miss/)||($snp_data[1] =~ /non/)||($snp_data[1] =~ /syn/)||(($snp_data[1] !~ /-/)&&($snp_data[1] !~ /in|del/)))&&($snp_data[2] =~ /^[1-9]{1}[0-9]*$/)&&($snp_data[0] =~ /^\s*[ATCG]\/([ATCG]\/)*[ATCG]\s*$/)) {
		#print "Short circuit check!\n";
		my @change = split ("/",$snp_data[0]);
		my $position = $snp_data[2];
		#The below if statement will check if the cdna matches whats written as reference in the snp file.
		#It could be that for instance in SNP file you have C as reference on - strand and your gene is on plus strand and the cdna at that position is T. This situation will NOT pass as FALSE below and be skipped.
		#A second check at lines 317 or 373 is also performed on codon level. The below 3 variable are not necessary, array brackets seems to be parsed in quotes..
		#my $cdna_check = $cdna_array[$position-1];
		#my $reverse_cdna_check = $reversebase{$cdna_array[$position-1]};
		#my $snpfile_check = $change[0];
		if (((($gene_location =~ /^((pos)|(plu)|([+])|(1))/)&&($snp_data[4] =~ /^((pos)|(plu)|([+])|(1))/))||(($gene_location =~ /^((-)|(neg)|(min)|(-1))/)&&($snp_data[4] =~ /^((-)|(neg)|(min)|(-1))/))) &&($cdna_array[$position-1] ne $change[0])) {
			print "Sense strand error at position $position(cdna: $cdna_array[$position-1], file: $change[0]). Skipping..\n";
			next;
		} elsif (((($gene_location =~ /^((-)|(neg)|(min)|(-1))/)&&($snp_data[4] =~ /^((pos)|(plu)|([+])|(1))/))||(($gene_location =~ /^((pos)|(plu)|([+])|(1))/)&&($snp_data[4] =~ /^((-)|(neg)|(min)|(-1))/))) &&($reversebase{$cdna_array[$position-1]} ne $change[0])) {
			print "Anti-sense strand error at position $position(reverse_cdna: $reversebase{$cdna_array[$position-1]}, file: $change[0]). Skipping..\n";
			next;
		}
		if (($position % 3 != 0)&&($position/3 <= $protein_length)) {
			my $cdna_codon = $cdna_array[(int($position/3)*3)].$cdna_array[(int($position/3)*3)+1].$cdna_array[(int($position/3)*3)+2];
			my @cdna_codon_array = ($cdna_array[(int($position/3)*3)], $cdna_array[(int($position/3)*3)+1], $cdna_array[(int($position/3)*3)+2]);
			my $fasta_aminoacid = $fasta_array[int($position/3)];
			my $cdna_aminoacid;
			foreach my $element (keys %degenerate_code) {
				for (my $i = 0;$i < $#{$degenerate_code{$element}};$i++) {
					if (${$degenerate_code{$element}}[$i] eq $cdna_codon) {
						$cdna_aminoacid = $element;
					}
				}
			}
			if ($cdna_aminoacid eq $fasta_aminoacid) {
				print "Fasta data matches cdna data at position $position...\n";
			} else {
				print "CAUTION, no match at position $position to your fasta file...\nMust have been a wrong transcript..Skipping this mutation\n";
				next;
			}
			my $cdna_aminoacid_new;
			my $type;
			my $changed_base_number = int((($position/3)-int($position/3))/0.3) - 1;
			for (my $i = 1;$i < scalar (@change);$i++) {
				if ($change[$i] =~ /^[ATCG]{1}$/) {
					if ((($gene_location =~ /^((pos)|(plu)|([+])|(1))/)&&($snp_data[4] =~ /^((-)|(neg)|(min)|(-1))/))||(($gene_location =~ /^((-)|(neg)|(min)|(-1))/)&&($snp_data[4] =~ /^((pos)|(plu)|([+])|(1))/))) {
						if ($change[$i] eq "A") {
							$change[$i] = "T";
						} elsif ($change[$i] eq "T") {
							$change[$i] = "A";
						} elsif ($change[$i] eq "G") {
							$change[$i] = "C";
						} elsif ($change[$i] eq "C") {
							$change[$i] = "G";
						}
					}
					$cdna_codon_array[$changed_base_number] = $change[$i];
					my $cdna_codon_new = join("",@cdna_codon_array);
					foreach my $element (keys %degenerate_code) {
						for (my $i = 0;$i < $#{$degenerate_code{$element}};$i++) {
							if (${$degenerate_code{$element}}[$i] eq $cdna_codon_new) {
								$cdna_aminoacid_new = $element;
							}
						}
					}
					if ($cdna_aminoacid_new eq $cdna_aminoacid) {
						$type = "Synonymous";
					} elsif ($cdna_aminoacid_new eq "X") {
						$type = "Nonsense";
					} else {
						$type = "Non-synonymous";
					}
					print $snpfile_missense_textplot $protein_name." ".int($position/3)*1000000 ." ".(int($position/3)+1)*1000000 ." "."p.".$cdna_aminoacid. (int($position/3)+1) .$cdna_aminoacid_new." "."type=".$type.","."validation=".$validation_status.","."svgclass=mut".","."svgid=".$cdna_aminoacid. (int($position/3)+1) .$cdna_aminoacid_new."_rsID_".$snp_data[$#snp_data-1]."_$i"."_$missense_counter".",svgdbsource=".$snp_data[$#snp_data].",svgpolyphen2=".$prediction_data{"polyphen2"}.",svgsift=".$prediction_data{"sift"}.",svgipvMAF=".$ipvMAF."\n";
				} elsif (($change[$i] =~ /^-$/)||(scalar(split("",$change[$i])) % 3 != 1)) {
					$type = "Frameshift";
					print $snpfile_missense_textplot $protein_name." ".int($position/3)*1000000 ." ".(int($position/3)+1)*1000000 ." "."p.".$cdna_aminoacid. (int($position/3)+1) ."fs"." "."type=".$type.","."validation=".$validation_status.","."svgclass=mut".","."svgid=".$cdna_aminoacid. (int($position/3)+1) ."fs"."_rsID_".$snp_data[$#snp_data-1]."_$i"."_$missense_counter".",svgdbsource=".$snp_data[$#snp_data].",svgpolyphen2=".$prediction_data{"polyphen2"}.",svgsift=".$prediction_data{"sift"}.",svgipvMAF=".$ipvMAF."\n";
				}
			}
		} elsif ($position/3 <= $protein_length) {
			my $cdna_codon = $cdna_array[((int($position/3)-1)*3)].$cdna_array[((int($position/3)-1)*3)+1].$cdna_array[((int($position/3)-1)*3)+2];
			my @cdna_codon_array = ($cdna_array[((int($position/3)-1)*3)], $cdna_array[((int($position/3)-1)*3)+1], $cdna_array[((int($position/3)-1)*3)+2]);
			my $fasta_aminoacid = $fasta_array[int($position/3)-1];
			my $cdna_aminoacid;
			foreach my $element (keys %degenerate_code) {
				for (my $i = 0;$i < $#{$degenerate_code{$element}};$i++) {
					if (${$degenerate_code{$element}}[$i] eq $cdna_codon) {
						$cdna_aminoacid = $element;
					}
				}
			}
			if ($cdna_aminoacid eq $fasta_aminoacid) {
				print "Fasta data matches cdna data at position $position...\n";
			} else {
				print "CAUTION, no match at position $position to your fasta file...\nMust have been a wrong transcript..Skipping this mutation\n";
				next;
			}
			my $cdna_aminoacid_new;
			my $type;
			my $changed_base_number = 2;
			for (my $i = 1;$i < scalar (@change);$i++) {
				if ($change[$i] =~ /^[ATCG]{1}$/) {
					if ((($gene_location =~ /^((pos)|(plu)|([+])|(1))/)&&($snp_data[4] =~ /^((-)|(neg)|(min)|(-1))/))||(($gene_location =~ /^((-)|(neg)|(min)|(-1))/)&&($snp_data[4] =~ /^((pos)|(plu)|([+])|(1))/))) {
						if ($change[$i] eq "A") {
							$change[$i] = "T";
						} elsif ($change[$i] eq "T") {
							$change[$i] = "A";
						} elsif ($change[$i] eq "G") {
							$change[$i] = "C";
						} elsif ($change[$i] eq "C") {
							$change[$i] = "G";
						}
					}
					$cdna_codon_array[$changed_base_number] = $change[$i];
					my $cdna_codon_new = join("",@cdna_codon_array);
					foreach my $element (keys %degenerate_code) {
						for (my $i = 0;$i < $#{$degenerate_code{$element}};$i++) {
							if (${$degenerate_code{$element}}[$i] eq $cdna_codon_new) {
								$cdna_aminoacid_new = $element;
							}
						}
					}
					if ($cdna_aminoacid_new eq $cdna_aminoacid) {
						$type = "Synonymous";
					} elsif ($cdna_aminoacid_new eq "X") {
						$type = "Nonsense";
					} else {
						$type = "Non-synonymous";
					}
					print $snpfile_missense_textplot $protein_name." ".(int($position/3)-1)*1000000 ." ".(int($position/3))*1000000 ." "."p.".$cdna_aminoacid.int($position/3) .$cdna_aminoacid_new." "."type=".$type.","."validation=".$validation_status.","."svgclass=mut".","."svgid=".$cdna_aminoacid.int($position/3) .$cdna_aminoacid_new."_rsID_".$snp_data[$#snp_data-1]."_$i"."_$missense_counter".",svgdbsource=".$snp_data[$#snp_data].",svgpolyphen2=".$prediction_data{"polyphen2"}.",svgsift=".$prediction_data{"sift"}.",svgipvMAF=".$ipvMAF."\n";
				} elsif (($change[$i] =~ /^-$/)||(scalar(split("",$change[$i])) % 3 != 1)) {
					$type = "Frameshift";
					print $snpfile_missense_textplot $protein_name." ".(int($position/3)-1)*1000000 ." ".(int($position/3))*1000000 ." "."p.".$cdna_aminoacid.int($position/3) ."fs"." "."type=".$type.","."validation=".$validation_status.","."svgclass=mut".","."svgid=".$cdna_aminoacid.int($position/3) ."fs"."_rsID_".$snp_data[$#snp_data-1]."_$i"."_$missense_counter".",svgdbsource=".$snp_data[$#snp_data].",svgpolyphen2=".$prediction_data{"polyphen2"}.",svgsift=".$prediction_data{"sift"}.",svgipvMAF=".$ipvMAF."\n";
				}
			}
		}
		push (@SNPtextplot_inventory,$SNPtextplot_inventory_element);
		#WRONG_TRANSCRIPT:
		$missense_counter++;
	}
}
print "SNP-TEXT PLOT::OK\n";



print "Making variation tile plot...\n";
my @SNPtileplot_inventory;
open($snpfile, '<',"$PATH_domestic/circos-p/Input/$snp_name") or die "Cannot open the snp file!\n";
open(my $tilefile, '>',"$PATH_domestic/circos-p/datatracks/tile_plot.txt") or die "Cannot open the tile plot file!\n";
my $tile_ID = 0;
while (<$snpfile>) {
	chomp;
	my @each_line =  separator ($_);
	my @snp_data = ();
	push (@snp_data, $each_line[$basechange_number]);
	push (@snp_data, $each_line[$substitiontype_number]);
	push (@snp_data, $each_line[$substitioncoordinates_number]);
	push (@snp_data, $each_line[$validationstatus_number]);
	push (@snp_data, $each_line[$strand_number]);
	#Look inside the file for rsID
	for (my $i = 0;$i <= $#each_line;$i++) {
		if ($each_line[$i] =~ /rs[0-9]+/ ) {
			push(@snp_data, $each_line[$i]);
			last;
		}
		if ($i == $#each_line) {
			#If no rsID is found a NotAvailable string pushed instead
			push (@snp_data, "rsID_NotAvailable");
		}
	}
	#Look for variation source in the file
	for (my $i = 0;$i <= $#each_line;$i++) {
		if ($each_line[$i] =~ /dbsnp|clinvar|hgmd|phencode|customdb|^esp$|^\s*human\s*core\s*exome/i ) {
			push(@snp_data, $each_line[$i]);
			last;
		}
		if ($i == $#each_line) {
			#If no source is found than push a string instead
			push (@snp_data, "source_NotAvailable");
		}
	}
	if ($transcript_ID !~ /ProcessAll/) {
		if ($each_line[$transcript_ID_column] !~ /$transcript_ID/) {
			#You can turn on the below warning if you want but it might flod the screen with some inputs that contain a lot of transcripts.
			#print "Transcript filtered based on choice..\n";
			next;
		}
	}
	if (!defined $snp_data[2]){
		#I wanted to include the below warning however it really dominates the screen..
		#print "Encountered empty coding start. Must have been in an intron. Skipping..\n";
		next;
	}
	my $validation_status;
	#print @snp_data."\n";
	if (($snp_data[2] =~ /^[1-9]{1}[0-9]*$/) && ($snp_data[0] =~ /^\s*([ATCG]+|-)\/(([ATCG]+|-)\/)*([ATCG]+|-)\s*$/)) {
		if ($snp_data[3] =~ /^y.*/) {
			$validation_status = "Validated";
		} elsif ($snp_data[3] =~ /^n.*/) {
			$validation_status = "Not_Validated";
		} else {
			$validation_status = "N/A";
		}
		my @change = split ("/",$snp_data[0]);
		my @change_length = (0,0);
		my $IndexOfLongestChange = $#change;
		my $IndexOf2ndLongestChange = $#change;
		for (my $i = $#change;$i>=0;$i--) {
			my @splitted = split ("",$change[$i]);
			my $length = scalar(@splitted);
			if ($length > $change_length[$#change_length]) {
				shift @change_length;
				push (@change_length, $length);
				$IndexOf2ndLongestChange = $IndexOfLongestChange;
				$IndexOfLongestChange = $i;
			}
		}
		my $change_length_aa;
		if ($change_length[$#change_length] % 3 != 0) {
			$change_length_aa = int($change_length[$#change_length]/3)+1;
		} else {
			$change_length_aa = int($change_length[$#change_length]/3);
		}
		my $position = $snp_data[2];
		my $type = $snp_data[1];
		if ($snp_data[1] !~ /subst|miss|non|syn|in|del/) {
			if(($snp_data[1] !~ /-/) && ($snp_data[1] =~ /^\s*[ATCG]\/([ATCG]\/)*[ATCG]\s*$/)) {
				$type = "subst";
			} else {
				$type = "indel";
			}
		}
		#***DuplicateCheck***
		my $SNPtileplot_inventory_element = "";
		for (my $i = 0;$i<=$#snp_data;$i++){
			$SNPtileplot_inventory_element = $SNPtileplot_inventory_element.$snp_data[$i];
		}
		$SNPtileplot_inventory_element = $SNPtileplot_inventory_element.$type;
		if(grep {$SNPtileplot_inventory[$_] =~ $SNPtileplot_inventory_element} (0..$#SNPtileplot_inventory)){
			print "Duplicate line detected (might also be multiple SNPs combined under single rsID or base change column..). Skipping this tile..\n";
			next;
		}
		#***DuplicateCheck***
		#***InsertionOrDeletion***
		my $InsOrDel;
		if ($type =~ /in|del/) {
			if (($snp_data[0] =~ /^\s*-\/.*/) || ($change_length[$#change_length]>length($change[0]))) {
				$InsOrDel = "insertion";
			} else {
				$InsOrDel = "deletion";
			}
		} else {
			$InsOrDel = "substitution";
		}
		#***InsertionOrDeletion***
		
		#***Is it a frameshift***
		my $frameshift;
		if ($change[0] =~ /^\s*-/) {
			if ($change_length[$#change_length] % 3 == 0) {
				$frameshift = "";
			} else {
				$frameshift = "frameshift";
			}
		} elsif (($change[$IndexOfLongestChange] !~ /^\s*-/) && ($IndexOfLongestChange != 0)) {
			my $difference = abs($change_length[$#change_length]-length($change[0]));
			if ($difference % 3 == 0) {
				$frameshift = "";
			} else {
				$frameshift = "frameshift";
			}
		} elsif ($change[$IndexOf2ndLongestChange] !~ /^\s*-/) {
			my $difference = abs($change_length[$#change_length-1]-length($change[0]));
			if ($difference % 3 == 0) {
				$frameshift = "";
			} else {
				$frameshift = "frameshift";
			}
		} else {
			my $difference = length($change[0]);
			if ($difference % 3 == 0) {
				$frameshift = "";
			} else {
				$frameshift = "frameshift";
			}
		}
		#***Is it a frameshift***
		
		#the definition for all tile svg class is ".tile", the svg id is "#tileID_position_changelength_InsOrDel_Frameshift"
		if (($position % 3 != 0)&&($position/3 <= $protein_length)) {
			if ($InsOrDel ne "deletion") {
				print $tilefile $protein_name." ".(int($position/3)-$change_length_aa/2)*1000000 ." ".(int($position/3)+$change_length_aa/2)*1000000 ." "."type=".$type.","."validation=".$validation_status.","."svgclass=tile".","."svgid="."tile".$tile_ID."_".$position."_".$change_length_aa."_".$InsOrDel."_".$frameshift.","."svgdbsource=".$snp_data[$#snp_data].","."svgtilersid=".$snp_data[$#snp_data-1]."\n";
			} else {
				print $tilefile $protein_name." ".(int($position/3))*1000000 ." ".(int($position/3)+$change_length_aa)*1000000 ." "."type=".$type.","."validation=".$validation_status.","."svgclass=tile".","."svgid="."tile".$tile_ID."_".$position."_".$change_length_aa."_".$InsOrDel."_".$frameshift.","."svgdbsource=".$snp_data[$#snp_data].","."svgtilersid=".$snp_data[$#snp_data-1]."\n";
			}
		} elsif ($position/3 <= $protein_length) {
			if ($InsOrDel ne "deletion") {
				print $tilefile $protein_name." ".(int($position/3)-1-$change_length_aa/2)*1000000 ." ".(int($position/3)-1+$change_length_aa/2)*1000000 ." "."type=".$type.","."validation=".$validation_status.","."svgclass=tile".","."svgid="."tile".$tile_ID."_".$position."_".$change_length_aa."_".$InsOrDel."_".$frameshift.","."svgdbsource=".$snp_data[$#snp_data].","."svgtilersid=".$snp_data[$#snp_data-1]."\n";
			} else {
				print $tilefile $protein_name." ".(int($position/3)-1)*1000000 ." ".(int($position/3)-1+$change_length_aa)*1000000 ." "."type=".$type.","."validation=".$validation_status.","."svgclass=tile".","."svgid="."tile".$tile_ID."_".$position."_".$change_length_aa."_".$InsOrDel."_".$frameshift.","."svgdbsource=".$snp_data[$#snp_data].","."svgtilersid=".$snp_data[$#snp_data-1]."\n";
			}
		}
		push (@SNPtileplot_inventory,$SNPtileplot_inventory_element);
	}
	$tile_ID++;
}
print "TILE PLOT::OK\n";

#***MODICT plot is experimental***
my $modictplot_answer = "no";
goto SKIP_MODICT_1;
print "Would you like to include a MODICT plot?\n";
$modictplot_answer = <STDIN>;
chomp $modictplot_answer;
if ($modictplot_answer !~ /^y.*/) {
	print "Skipping MODICT plot...\n";
	goto SKIP_MODICT_1;
}
print "Making MODICT plot...\n";
open(my $modictfile, '>',"$PATH_domestic/circos-p/datatracks/modict_plot.txt") or die "Cannot open the modict plot file!\n";
print "Please type in the name of your iterator results in circos-p/input/..\n";
my $iterator_results = <STDIN>;
chomp $iterator_results;
SKIP_MODICT_1:
print "Please type in the name of your conservation file in circos-p/input/..\n";
my $conservation = <STDIN>;
chomp $conservation;
if ($modictplot_answer !~ /^y.*/) {
	goto SKIP_MODICT_2;
}
open(my $iteratorfile, '<',"$PATH_domestic/circos-p/Input/$iterator_results") or die "Cannot open the iterator file!\n";
SKIP_MODICT_2:
open(my $conservationfile, '<',"$PATH_domestic/circos-p/Input/$conservation") or goto SKIP_MODICT_1;
my @iterator_array;
my @conservation_array;
if ($modictplot_answer !~ /^y.*/) {
	goto SKIP_MODICT_3;
}
while (<$iteratorfile>) {
	chomp $_;
	push (@iterator_array,$_);
}
SKIP_MODICT_3:
while (<$conservationfile>) {
	chomp $_;
	push (@conservation_array,$_);
}
my $conservation_min = take_min(@conservation_array);
#the min value can create problems sometimes, print the below line to see if the real mean is picked up.
#print "Your min value is $conservation_min.\n";
my $conservation_max = take_max(@conservation_array);
#same for max
#print "Your max value is $conservation_max.\n";
if ($modictplot_answer !~ /^y.*/) {
	goto SKIP_MODICT_4;
}
if (((scalar(@conservation_array) == (2*scalar (@iterator_array))) || (scalar(@conservation_array) == (2*scalar (@iterator_array))+1)) && (((scalar (@iterator_array))*2 == $protein_length) || ((scalar (@iterator_array))*2+1 == $protein_length))) {
	print "Your conservation and iterator files are in phase. Continuing....\n";
} else {
	print "Please check your conservation and iterator files, there might be a problem in the number of lines. Continuing....\n";
}
for (my $i = 0; $i < scalar(@iterator_array);$i++) {
	my $show_status = "yes";
	if (2*$i + 1 <$domains[0]) {
		$show_status = "no";
	}
	my $j = 1;
	until ($j+1 > $#domains) {
		if ((2*$i + 1 > $domains[$j]) && (2*$i + 1 < $domains[$j+1])) {
			$show_status = "no";
		}
		$j += 2;
	}
	if (2*$i + 1 > $domains[$#domains]) {
		$show_status = "no";
	}
	print $modictfile $protein_name." ".($i)*2000000 ." ".($i+1)*2000000 ." ".$iterator_array[$i]." "."conservation=".sprintf("%.1f", ($conservation_array[2*$i] + $conservation_array[2*$i + 1])/2).",show="."$show_status"."\n";
}
print "MODICT PLOT::OK\n";


SKIP_MODICT_4:
print "Making the highlights file...\n";
open(my $highlightfile, '>',"$PATH_domestic/circos-p/datatracks/highlights.txt") or die "Cannot open the highlights file!\n";
if ($domains[0] > 1) {
	my $i = 0;
	until (($i+2) > $domains[0]) {
		my $element = shift (@conservation_array);
		print $highlightfile $protein_name." ". (0+$i)*1000000 ." ".($i+1)*1000000 ." type=Coil,conservation=$element,property=n/a,svgid=Residue_".((0+$i)+1)."_Conservation-Score_$element\n";
		$i++;
	}
}
foreach my $element (@domains) {
	my @index_array = grep {$domains[$_] == $element} 0..$#domains;
	if (($index_array[0] % 2 == 0)&&($index_array[0] != $#domains)) {
		my $property = shift(@domain_properties);
		my $i = 0;
		until (($domains[$index_array[0]]+ $i) > $domains[$index_array[0]+1]) {
			my $element = shift (@conservation_array);
			print $highlightfile $protein_name." ".($domains[$index_array[0]] + $i - 1)*1000000 ." ".($domains[$index_array[0]]+ $i)*1000000 ." type=Domain,conservation=$element,property=$property,svgid=Residue_".(($domains[$index_array[0]] + $i - 1)+1)."_Conservation-Score_$element,svgclass=$property\n";
			$i++;
		}
	} elsif ($index_array[0] != $#domains) {
		my $i = 1;
		until (($domains[$index_array[0]] + $i + 1) > $domains[$index_array[0]+1]) {
			my $element = shift (@conservation_array);
			print $highlightfile $protein_name." ".($domains[$index_array[0]] + $i - 1)*1000000 ." ".($domains[$index_array[0]]+ $i)*1000000 ." type=Coil,conservation=$element,property=n/a,svgid=Residue_".(($domains[$index_array[0]] + $i - 1)+1)."_Conservation-Score_$element\n";
			$i++;
		}
	}
}
if ($domains[$#domains] < $protein_length) {
	my $i = 1;
	until (($domains[$#domains] + $i) > $protein_length) {
		my $element = shift (@conservation_array);
		print $highlightfile $protein_name." ".($domains[$#domains] + $i - 1)*1000000 ." ".($domains[$#domains] + $i)*1000000 ." type=Coil,conservation=$element,property=n/a,svgid=Residue_".(($domains[$#domains] + $i - 1)+1)."_Conservation-Score_$element\n";
		$i++;
	}
}
print "HIGHLIGHTS::OK\n";


print "Would you like to create markup file?[yes/no]\n";
$_ = <STDIN>;
chomp $_;
my $markup_choice = $_;
if ($_ !~ /^y.*/) {
	print "Skipping connector graph...\n";
	goto SKIP_CONNECTOR;
} else {
   $markup_choice = "yes";
}
print "Making the markup file...\n";
my @markup = ();
my %markup_colors;
my $markup_count = 0;
markup();
open(my $connectorfile, '>',"$PATH_domestic/circos-p/datatracks/connector.txt") or die "Cannot open the connector file!\n";
open(my $connector_text_file, '>',"$PATH_domestic/circos-p/datatracks/connector_text.txt") or die "Cannot open the connector_text file!\n";
for (my $i = 0; $i < scalar(@markup); $i += 4) {
		print $connectorfile $protein_name." ".($markup[$i+1]+$markup[$i] - 1)/2*1000000 ." ".($markup[$i]-1)*1000000 ." property=".$markup[$i+3]."\n";
		print $connectorfile $protein_name." ".($markup[$i+1]+$markup[$i] - 1)/2*1000000 ." ".($markup[$i+1])*1000000 ." property=".$markup[$i+3]."\n";
		print $connector_text_file $protein_name." ".($markup[$i] - 1)*1000000 ." ".($markup[$i+1])*1000000 ." ".$markup[$i+2]." property=".$markup[$i+3].","."svgclass=connector".","."svgid="."Connector_".$markup[$i]."-".$markup[$i+1]."\n";
}
print "MARKUP::OK\n";
SKIP_CONNECTOR:

print "Your plot files are created under circos-p/datatracks...\n";
#print "Your plot files are created under circos/datatracks...\nThank you and good bye...\n";

print "Configuring plots.conf file from plots template..\n";
open(my $plotfile, '>',"$PATH_domestic/circos-p/datatracks/plot.txt") or die "Cannot write to plot file!\n";
open(my $templatefile, '<',"$PATH_domestic/circos-p/templates/plots_template.txt") or die "Cannot open the template file!\n";
#Parameters that can go crazy
$missense_counter = $missense_counter || 625;
my $label_size_missense = int(40/(sqrt($missense_counter)/15));
if ($label_size_missense > 40) {
	$label_size_missense = 40;
}
my $tile_thickness = int(50/(sqrt($missense_counter)/25));
if ($tile_thickness > 50) {
	$tile_thickness = 50;
}
my $link_thickness_missense = int(6/(($missense_counter**(7/12))/28));
if ($link_thickness_missense > 6) {
	$link_thickness_missense = 6;
}
#Parameters that can go crazy
while (<$templatefile>) {
	if ($_ =~ /#coil_1/) {
		print $plotfile "r1 = eval(qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1)[remap_round(var(conservation),".$conservation_min.",".$conservation_max.",0,9)] .'r')\n";
	} elsif ($_ =~ /#domain_colors/) {
		foreach my $element (keys %domain_colors) {
			my @results= prefixer ($domain_colors{$element});
			print $plotfile "<rule>\ncondition = var(type) eq 'Domain' && var(property) eq "."'$element'"."\n"."stroke_color = ".$domain_colors{$element}."\n"."fill_color = ".$results[0].$results[1]."\n"."r1 = eval(qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1)[remap_round(var(conservation),".$conservation_min.",".$conservation_max.",0,9)] .'r')"."\n"."flow = continue\n</rule>\n";
		}
	} elsif ($_ =~ /#label_size_sequence/) {
		print $plotfile "label_size = ".int(40/(sqrt(scalar(@fasta_array))/20))."p\n";
	} elsif ($_ =~ /#glyph_size_scatter/) {
		print $plotfile "glyph_size = ".int(45/(sqrt(scalar(@fasta_array))/20))."p\n";
	} elsif ($_ =~ /#label_size_missense/) {
		print $plotfile "label_size = ".$label_size_missense."p\n";
	} elsif ($_ =~ /#markup_colors1/) {
		foreach my $element (keys %markup_colors) {
			#Not needed here.
			#$result_prefix= prefixer ($markup_colors{$element});
			print $plotfile "<rule>\ncondition = var(property) eq "."'$element'"."\n"."color = ".$markup_colors{$element}."\n"."flow = continue\n</rule>\n";
		}
	} elsif ($_ =~ /#markup_colors2/) {
		foreach my $element (keys %markup_colors) {
			#Not needed here.
			#$result_prefix= prefixer ($markup_colors{$element});
			print $plotfile "<rule>\ncondition = var(property) eq "."'$element'"."\n"."color = ".$markup_colors{$element}."\n"."flow = continue\n</rule>\n";
		}
	} elsif ($_ =~ /#markup_choice1/) {
		print $plotfile "show = ".$markup_choice."\n";
	} elsif ($_ =~ /#markup_choice2/) {
		print $plotfile "show = ".$markup_choice."\n";
	} elsif ($_ =~ /#tile_thickness/) {
		print $plotfile "thickness = ".$tile_thickness."p\n";
	} elsif ($_ =~ /#link_thickness/) {
		print $plotfile "link_thickness = ".$link_thickness_missense."p\n";
	}
	print $plotfile $_;
}
print "Plot file created.\n";
print "Renaming extension.\n";
open($plotfile, '<',"$PATH_domestic/circos-p/datatracks/plot.txt") or die "Cannot read from plot file!\n";
copy ($plotfile, "$PATH_domestic/circos-p/datatracks/plot.conf") or die "$!\n";
print "You can either continue for image generation or run circos yourself.\ntype 'exit' and enter to quit or press any key and enter to continue..\n";
my $continue = <STDIN>;
chomp $continue;
if ($continue =~ /exit/) {
	exit;
}

#close file handles
close $plotfile or die "$!\n";
close $templatefile or die "$!\n";
if ($markup_choice =~ /yes/) {
close $connectorfile or die "$!\n";
close $connector_text_file or die "$!\n";
}
close $highlightfile or die "$!\n";
close $conservationfile or die "$!\n";
#close $iteratorfile or die "$!\n";
close $snpfile or die "$!\n";
close $tilefile or die "$!\n";
close $snpfile_missense_textplot or die "$!\n";
close $sequencefile or die "$!\n";
close $scatterfile or die "$!\n";
close $karyotypefile or die "$!\n";
close $cdnafile or die "$!\n";
close $fastafile or die "$!\n";
#close file handles
print "Filehandles at datatracks folder are closed.\nYou can now change these folders before proceeding.\nPress enter to continue..\n";
<STDIN>;

#Run circos
print "Running circos..\n";
my $circos = "C:/strawberry/circos-0.67-7/bin/circos";
my $circos_results = system($^X, $circos, "-conf=$FindBin::Bin/../circos-p/templates/circos_template.conf", "-outputdir=$FindBin::Bin/../circos-p/Output");
print "Your image is created..\n";
#Run circos

#Inject javascript
print "Injecting Javascript..\n";
copy("$PATH_domestic/circos-p/Output/circos.svg", "$PATH_domestic/circos-p/Output/circos.txt") or die "$!\n";
my $javascriptfile;
if ($markup_choice =~ /yes/i) {
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


sub list_creation {
	$domain_count++;
	REDEFINE_1:
	print "Please type the start of domain_$domain_count...[Hint: Enter integer and press enter]\n";
	$_ = <STDIN>;
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		print "Few simple rules for entering domains:\n1. Only numbers are allowed.\n2. Cannot be larger than your protein's aa length.\n3. No negative numbers.\n";
		goto REDEFINE_1;
	}
	if (($#domains >= 1) && ($_ <= $domains[$#domains])){
		print "1. You cannot enter overlaping regions.\n2. You cannot enter a value smaller than the end of previous domain.\nHint: If you have overlaping domains in your protein (A and B for instance),\nyou can simply enter the name for first domain A_and_B-part1 and the second B-part2.\nUse underscores instead of spaces, they will be replaced later on.\n";
		goto REDEFINE_1;
	}
	my $i = $_;
	push (@domains, $_);
	LC_RETRY:
	print "Please type the end of domain_$domain_count...[Hint: Enter integer and press enter]\n";
	$_ =  <STDIN>;
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		print "Few simple rules for entering domains:\n1. Only numbers are allowed.\n2. Cannot be larger than your protein's aa length.\n3. No negative numbers.\n";
		goto LC_RETRY;
	}
	if (($#domains >= 1) && ($_ <= $domains[$#domains])){
		print "1. You cannot enter overlaping regions.\n2. You cannot enter a value smaller than the end of previous domain.\nHint: If you have overlaping domains in your protein (A and B for instance),\nyou can simply enter the name for first domain A_and_B-part1 and the second B-part2.\nUse underscores instead of spaces, they will be replaced later on.\n";
		goto LC_RETRY;
	}
	my $j = $_;
	if ($j <= $i) {
		print "You cannot enter an equal or smaller value...please retry.\n";
		goto LC_RETRY;
	}
	push (@domains, $_);
	my $property;
	print "Would you like to assign a property to this domain?\nProperties are necessary to attain colors..[yes/no]\n";
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^y.*/) {
		print "What would be the name of this property?[e.g X_domain, X-domain]\n";
		REDEFINE_2:
		$_ = <STDIN>;
		chomp $_;
		if ($_ =~ /\s+|\/+|\\+|[()]+|\[+|\]+/) {
			print "Spaces,slashes or pharanthesis are not allowed. Use underscores for spaces instead. Please retry:\n";
			goto REDEFINE_2;
		}
		$property = $_;
		print "Please enter a color for this region that circos understands..[eg. vdblue, lmagenta, vvdbrown..]\nIf you see black instead in your output you probably entered an undefined color.\n";
		$_ = <STDIN>;
		chomp $_;
		$domain_colors{$property} = $_;
	} else {
		$property = "n/a";
	}
	push (@domain_properties, $property);
	print "Are there more domains in your protein?[yes/no]\n";
	$_ =  <STDIN>;
	chomp $_;
	until (($_ =~ /^n.*/) || ($_ !~ /^y.*/)) {
		list_creation ($_);
	}
}

sub markup {
	$markup_count++;
	REDEFINE_MARKUP_1:
	print "Please type the start of region_$markup_count...[Hint: Enter integer and press enter]\n";
	$_ = <STDIN>;
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		print "Few simple rules for entering markups:\n1. Only numbers are allowed.\n2. Cannot be larger than your protein's aa length.\n3. No negative numbers.\n";
		goto REDEFINE_MARKUP_1;
	}
	#I initally inserted here the below code. But I think it should be OK for markups to overlap.
	#if (($#markup >= 3) && ($_ < $markup[$#markup-2])){
	#	print "1. You cannot enter overlaping regions.\n2. You cannot enter a value smaller than the end of previous markup.\n";
	#	goto REDEFINE_MARKUP_1;
	#}
	my $i = $_;
	push (@markup, $_);
	MU_RETRY:
	print "Please type the end of region_$markup_count...[Hint: Enter integer and press enter]\n";
	$_ =  <STDIN>;
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		print "Few simple rules for entering markups:\n1. Only numbers are allowed.\n2. Cannot be larger than your protein's aa length.\n3. No negative numbers.\n";
		goto MU_RETRY;
	}
	#I initally inserted here the below code. But I think it should be OK for markups to overlap.
	#if (($#markup >= 3) && ($_ < $markup[$#markup-2])){
	#	print "1. You cannot enter overlaping regions.\n2. You cannot enter a value smaller than the end of previous markup.\n";
	#	goto MU_RETRY;
	#}
	my $j = $_;
	#Initially I have included the below code, but I modified it to prohibit from only being smaller than the start...
	if ($j < $i) {
		print "You cannot enter a smaller value than the start..Please retry.\n";
		goto MU_RETRY;
	}
	push (@markup, $_);
	print "What is the name of this region?[e.g Interaction_with_target_X]\n";
	REDEFINE_MARKUP_2:
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /\s+|\/+|\\+|[()]+|\[+|\]+/) {
		print "Spaces,slashes or pharanthesis are not allowed. Use underscores for spaces instead. Please retry:\n";
		goto REDEFINE_MARKUP_2;
	}
	push (@markup, $_);
	my $property;
	print "Would you like to assign a property to this region?\nProperties are necessary to attain colors..[yes/no]\n";
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^y.*/) {
		print "What would be the name of this property?[e.g Interaction_with_target_X]\n";
		REDEFINE_MARKUP_3:
		$_ = <STDIN>;
		chomp $_;
		if ($_ =~ /\s+|\/+|\\+|[()]+|\[+|\]+/) {
			print "Spaces,slashes or pharanthesis are not allowed. Use underscores for spaces instead. Please retry:\n";
			goto REDEFINE_MARKUP_3;
		}
		$property = $_;
		print "Please enter a color for this markup that circos understands..[eg. vdblue, lmagenta, vvdbrown..]\nIf you see black instead in your output you probably entered an undefined color.\n";
		$_ = <STDIN>;
		chomp $_;
		$markup_colors{$property} = $_;
	} else {
		$property = "n/a";
	}
	push (@markup, $property);
	print "Are there more regions that you want to mark in your protein?[yes/no]\n";
	$_ =  <STDIN>;
	chomp $_;
	until (($_ =~ /^n.*/) || ($_ !~ /^y.*/)) {
		markup ($_);
	}
}

sub skip_header {
  my $FH = shift;
  <$FH>;
}


sub prefixer {
	my $quiery = $_[0];
	my @splitted = split("",$quiery);
	my $keyword1 = $splitted[0].$splitted[1].$splitted[2];
	#print $keyword1."\n";
	my $keyword2 = $splitted[0].$splitted[1];
	#print $keyword2."\n";
	my $keyword3 = $splitted[0];
	#print $keyword3."\n";
	my @keywords = ($keyword1,$keyword2,$keyword3);
	my @tonnage = ("vvl","vl","l","d","vd","vvd");
	my $result_prefix = "";
	for (my $i = 0;$i<=$#keywords;$i++) {
		my $signal = 0;
		for (my $j = 0;$j<=$#tonnage;$j++) {
			if ($tonnage[$j] eq $keywords[$i]) {
				$result_prefix = $tonnage[$j];
				$signal = 1;
				last;
			}
		}
		if ($signal == 1) {
			last;
		}
	}
	#print $result_prefix."\n";
	$quiery =~ s/$result_prefix//;
	#print $quiery."\n";
	if ($result_prefix eq "") {
		$result_prefix = "d";
	} elsif ($result_prefix eq "vvd") {
		$result_prefix = "vd";
	} elsif ($result_prefix eq "l") {
		$result_prefix = "";
	} else {
		my @index_match = grep {$tonnage[$_] eq $result_prefix} (0..$#tonnage);
		$result_prefix = $tonnage[$index_match[0]+1];
	}
	#print $result_prefix."\n";
	
	my @results;
	push (@results,$result_prefix);
	push (@results,$quiery);
	return @results;
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