#!/usr/bin/perl
package ipv_modules::variation;
use strict;
use warnings;
use utf8;
use Data::Dumper qw(Dumper);
use File::Basename qw(basename dirname);
use feature qw(say current_sub);
use Exporter qw(import);
use List::Util qw(max);
use Cwd qw(abs_path);
use lib dirname(abs_path $0);
use ipv_modules::consumeInput qw(consumeInput);

our $VERSION = 0.01;
our @EXPORT_OK = qw(renderVar);

sub renderVar {
	my (
		$protein_name, 
		$protein_length,
		$consumer, 
		$configJSON, 
		$cCache, 
		$degenerate_code, 
		$fasta_array,
		$cdna_array
	) = @_;
	my %degenerate_code = %{$degenerate_code};
	my @fasta_array = @{$fasta_array};
	my @cdna_array = @{$cdna_array};
	my $snp_name;
	REENTER_SNP:
	$consumer -> query([
		"Please provide the name of the SNP file...[e.g SNP.txt]",
		"An empty string, N/A or NA skips variation plots."
	]);
	$_ = consumeInput(
		["variation", "fileName"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {fileName}
		}
	);
	chomp $_;
	if ($_ =~ /^\s*$|^\s*n(?:\/)?a\s*$/gi) {
		$consumer -> info([
			"No variation file was provided.",
			"SKIPPING VARIATION PLOTS::OK"
		]);
		return [];
	}
	$consumer -> set("hasVariations", 1);
	$snp_name = $_;
	open(my $snpfile, '<', $cCache -> {path} -> {input} -> ($snp_name, "variation (SNPs)")) 
	or $consumer -> {configDefined}
		? $consumer -> err(["Cannot open $snp_name"])
		: goto REENTER_SNP;
	$consumer -> query("Should we skip the header?\n");
	my $answer = consumeInput(
		["variation", "skipHeader"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {skipHeader}
		}
	);
	chomp $answer;
	if ($answer =~ /y.*/) {
		$consumer -> query("How many times should the header be skipped?\n");
		my $header_skip_times = consumeInput(
			["variation", "skipHeader"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $cCache -> {variation} -> {skipHeaderCount}
			}
		);
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


	$consumer -> query([
			"What is the original separator of the data?",
			"(tabs, spaces, semicolons etc...)",
			"[Hint: If the spaces in the file is irregular, write 'whitespace'.]"
		]);
	my $separator = consumeInput(
		["variation", "separator"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {separator}
		}
	);
	chomp $separator;
	$consumer -> query([
		"You will be asked several questions below regarding SNP information.",
		"You are required to enter an integer only",
		"which corresponds to a column number.",
		"First column is numbered 1,",
		"second 2 and so on..",
		"Press any key and hit enter to continue"
	]);
	my $emtpty_response = consumeInput(
		[], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {pass}
		}
	);
	$consumer -> query([
		"Which column do you have the change in bases?",
		"[Hint: It is the column where the ",
		"ancesteral and alternative alleles",
		"are separated by a forward slash(eg.A/G,C/T/A..)]"
	]);
	my $basechange_number = consumeInput(
		["variation", "colBaseChange"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colBaseChange}
		}
	);
	chomp $basechange_number;
	$basechange_number -= 1;
	$consumer -> query([
		"Which column do you have the type of substitution?",
		"If you do not have a type set, you can also enter",
		"the previously given base change column."
	]);
	my $substitiontype_number = consumeInput(
		["variation", "colSubsType"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colSubsType}
		}
	);
	chomp $substitiontype_number;
	$substitiontype_number -= 1;
	$consumer -> query([
		"Which column do you have the substitution coordinates?",
		"[Hint: Choose the Coding Start column.]"
	]);
	my $substitioncoordinates_number = consumeInput(
		["variation", "colSubsCoords"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colSubsCoords}
		}
	);
	chomp $substitioncoordinates_number;
	$substitioncoordinates_number -= 1;
	$consumer -> query([
		"Which column do you have the validation status?",
		"If not applicapable, enter the same column as base change,",
		"the column where writes A/G,C/T/A etc.."
	]);
	my $validationstatus_number = consumeInput(
		["variation", "colValStat"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colValStat}
		}
	);
	chomp $validationstatus_number;
	$validationstatus_number -= 1;
	$consumer -> query([
		"Which column do you have the strand of the change?",
		"[Hint: This is the column where indicates + or - or 1 or -1 for the strand.]"
	]);
	my $strand_number = consumeInput(
		["variation", "colBaseChangeStrand"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colBaseChangeStrand}
		}
	);
	chomp $strand_number;
	$strand_number -= 1;
	$consumer -> query([ 
		"Which stand is your gene located in?",
		"[Hint: You can check this from publicly available genome browsers.",
		"You can enter plus,positive,+,1 or inverse of these parameters.]"
	]);
	my $gene_location = consumeInput(
		["variation", "colGeneStrand"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colGeneStrand}
		}
	);
	chomp $gene_location;
	$consumer -> query([
		"Please enter your transcript ID [e.g ENGXXXXXXXX,NM_YYYYYY. ].",
		"[Hint: Write 'ProcessAll' to skip transcript filtering..]"
	]);
	my $transcript_ID = consumeInput(
		["variation", "transcriptID"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {transcriptID}
		}
	);
	my $transcript_ID_column;
	chomp $transcript_ID;
	if ($transcript_ID =~ /ProcessAll/) {
		$transcript_ID_column = "N/A";
	} else {
		$consumer -> query("Please enter in which column your transcript IDs are located in\n");
		$transcript_ID_column = consumeInput(
			["variation", "colTranscriptID"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $cCache -> {variation} -> {colTranscriptID}
			}
		);
		$transcript_ID_column -= 1;
	}

	###PREDICTIONS###
	my $polyphen2;
	RETRY_POLYPHEN2:
	$consumer -> query([
		"Which column do you have the polyphen2 scores?",
		"[Hint: Choose the polyphen2 score column. If not available write enter 'NA']"
	]);
	$polyphen2 = consumeInput(
		["variation", "colPolyphen2"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colPolyphen2}
		}
	);
	chomp $polyphen2;
	if ($polyphen2 !~ /^[1-9]+[0-9]*$|^na$/i) {
		goto RETRY_POLYPHEN2;
	} elsif ($polyphen2 =~ /^[1-9]+[0-9]*$/) {
		$polyphen2 -= 1;
	}
	my $sift;
	RETRY_SIFT:
	$consumer -> query([
		"Which column do you have the sift scores?",
		"[Hint: Choose the sift score column.",
		"If not available write enter 'NA']"
	]);
	$sift = consumeInput(
		["variation", "colSift2"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {colSift2}
		}
	);
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
	$consumer -> query([
		"Which column do you have the MAF(minor allele frequency)?",
		"[Hint: This is a value between 0 and 1. If not available write enter 'NA']"
	]);
	$maf = consumeInput(
		["variation", "maf"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {variation} -> {maf}
		}
	);
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
	open(my $snpfile_missense_textplot, '>', $cCache -> {path} -> {datatracks} -> ("text_plot_missense")) or die "Cannot open the text plot file!\n";
	while (<$snpfile>) {
		$consumer -> {cache} -> {transliterate} -> {lfCr} -> (\$_);
		chomp;
		my @each_line =  separator ($_, $separator, $consumer, $configJSON, $cCache);
		my @snp_data = ();
		###PREDICTIONS###
		my %prediction_data = fetch_predictions(\@each_line, $polyphen2, $sift);
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
	open($snpfile, '<', $cCache -> {path} -> {input} -> ($snp_name, "variation (SNPs)")) or die "Cannot open the snp file!\n";
	open(my $tilefile, '>', $cCache -> {path} -> {datatracks} -> ("tile_plot")) or die "Cannot open the tile plot file!\n";
	my $tile_ID = 0;
	while (<$snpfile>) {
		$consumer -> {cache} -> {transliterate} -> {lfCr} -> (\$_);
		chomp;
		my @each_line =  separator ($_, $separator, $consumer, $configJSON, $cCache);
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
	
	close $snpfile or die "$!\n";
	close $tilefile or die "$!\n";
	close $snpfile_missense_textplot or die "$!\n";
	
	return [$missense_counter];
}

sub separator {
	my ($ref, $separator, $consumer, $configJSON, $cCache) = @_;
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
		$consumer -> query([
			"The separator of your choice was undefined",
			"Please enter the character itself..."
		]);
		my $undef_separator = consumeInput(
			["variation", "separator"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $cCache -> {variation} -> {separator}
			}
		);
		chomp $undef_separator;
		print "The character $undef_separator will be used as separator...\n";
		@array = split ("$undef_separator", $ref);
	}
	return @array;
}

sub skip_header {
  my $FH = shift;
  <$FH>;
}

sub fetch_predictions {
	my ($each_line, $polyphen2, $sift) = @_;
	my @each_line = @{$_[0]};
	my %hash = ("polyphen2" => "NA", "sift" => "NA");
	foreach my $element (keys %hash) {
		if ((eval("\$".$element) =~ /^[1-9]+[0-9]*$/) && (defined $each_line[eval("\$".$element)]) && ($each_line[eval("\$".$element)] !~ /^\s*\t*$/)) {
			$hash{$element} = $each_line[eval("\$".$element)];
		}
	}
	return %hash;
}

qq{
	0042 0065 006e 0020 0079 006f 006c 0063 0075 006c 0075 006b 0020 0075 0073 0074 0061 0073 0131 0079 0131 006d
	0048 0065 0072 0020 0067 0065 006d 0069 006e 0069 006e 0020 0074 0061 0079 0066 0061 0073 0131 0079 0131 006d
	0042 0065 006e 0069 006d 0020 0064 00fc 006e 0079 0061 006d 0020 006b 0075 015f 0062 0061 006b 0131 015f 0131
	0042 0065 006e 0020 0067 0065 006d 0069 006e 0069 006e 0020 006d 0061 0072 0074 0131 0073 0131 0079 0131 006d
	                                             0046 0065 0072 0068 0061 006e 0020 015e 0065 006e 0073 006f 0079
};