#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use feature 'say';
use IPC::System::Simple qw(system capture run);
use File::Copy qw(copy);
use File::Copy qw(move);
use File::Basename qw(basename dirname);
use File::Spec qw(catfile);
use Getopt::Long;
use FindBin;
use JSON::XS;
use List::Util qw(max);
use Cwd qw(abs_path);
use lib dirname(abs_path $0);
use ipv_modules::consumeInput qw(consumeInput);
use ipv_modules::config;
use ipv_modules::variation qw(renderVar);

my $PATH;
my $help;
my $explanation = [
	"Colors: Colors can be prefixed by 1 or 2 v's (stands for very),",
	"followed by l (light) or d (dark) and then root, all in small letters.",
	"These are the root color names:",
	"red, blue, green, yellow, orange, grey, purple",
	"magenta, brown, cyan, crimson, warmchampagne,",
	"ashlight, firelight, angelica.",
	"For example, 'vdred' means 'very dark red'.",
	"Invoking Circos:",
	"Make sure that the path specified in line 1221",
	"directs to the correct location.",
	"Otherwise circos will not be invoked."
];
my $version;
my $config;
my $configJSON;
my $consumer;

getopt();
defined $help ? say join("\n", @{$explanation}) : print "" ;
defined $version ? print "version 2.0\n" : print "" ;

if(defined $config){
	if(!(-e $config)){
		die "the configuration file you provided does not exist!";
	}
	my $configStr = do {
		local $/ = undef;
		open (my $configFile, "<", File::Spec -> catfile(dirname($config), basename($config))) 
		or die "Cannot open the config file!\n";
		<$configFile>;
	};
	$configJSON = decode_json $configStr;
	$consumer = ipv_modules::config -> new(basename($config), $configJSON);
} else {
	$consumer = ipv_modules::config -> new($config, $configJSON);
}

$| = consumeInput(
	["autoflush"], 
	$configJSON,
	{
		"callback" => $consumer -> autoflush -> {callback}
	}
);

my $cCache = $consumer -> {cache}; #consumer cache
$consumer -> preflight; #validate some parameters upfront

if ((defined $PATH)&&($PATH =~ /^.*[\/\\].*\s*|^-.*[\/\\].*\s*/)) {
	$PATH = $PATH;
	chomp $PATH;
} else {
	$consumer -> query("Please type the path or enter to skip to keep relative paths...\n");
	$_ = consumeInput(
		["path"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $cCache -> {path} -> {callback}
		}
	);
	chomp $_;
	$PATH = "-".$_;
	if ($PATH !~ /.*[\/\\].*/) {
		$PATH = "..";
	}
}
my $PATH_domestic = $PATH;
$PATH_domestic =~ s/-//g;
if ($PATH_domestic eq "") {
	$PATH_domestic = "..";
}

$cCache -> {path} -> {setRelPath} -> ($PATH_domestic);
$consumer -> set("scriptPath", dirname(abs_path(__FILE__)));
if ($consumer -> {configDefined}) {
	$consumer -> set("configDir", dirname(abs_path($config)));
}

my %degenerate_code = (
	"A" => ["GCT","GCC","GCA","GCG","Nonpolar"], 
	"R" => ["CGT","CGC","CGA","CGG","AGA","AGG","Positive"], 
	"N" => ["AAT","AAC","Polar"], 
	"D" => ["GAT","GAC","Negative"], 
	"C" => ["TGT","TGC","Polar"], 
	"Q" => ["CAA","CAG","Polar"], 
	"E" => ["GAA","GAG","Negative"], 
	"G" => ["GGT","GGC","GGA","GGG","Nonpolar"], 
	"H" => ["CAT","CAC","Positive"], 
	"I" => ["ATT","ATC","ATA","Nonpolar"], 
	"L" => ["TTA","TTG","CTT","CTC","CTA","CTG","Nonpolar"], 
	"K" => ["AAA","AAG","Positive"], 
	"M" => ["ATG","Nonpolar"], 
	"F" => ["TTT","TTC","Aromatic"], 
	"P" => ["CCT","CCC","CCA","CCG","Nonpolar"], 
	"S" => ["TCT","TCC","TCA","TCG","AGT","AGC","Polar"], 
	"T" => ["ACT","ACC","ACA","ACG","Polar"], 
	"W" => ["TGG","Aromatic"], 
	"Y" => ["TAT","TAC","Aromatic"], 
	"V" => ["GTT","GTC","GTA","GTG","Nonpolar"], 
	"X" => ["TAA","TGA","TAG","STOP"]
);
my %aa_names = (
	"A" => "Alanine", 
	"R" => "Arginine", 
	"N" => "Asparagine", 
	"D" => "Aspartic-Acid", 
	"C" => "Cysteine", 
	"Q" => "Glutamine", 
	"E" => "Glutamic-Acid", 
	"G" => "Glycine", 
	"H" => "Histidine", 
	"I" => "Isoleucine", 
	"L" => "Leucine", 
	"K" => "Lysine", 
	"M" => "Methionine", 
	"F" => "Phenylalanine", 
	"P" => "Proline", 
	"S" => "Serine", 
	"T" => "Threonine", 
	"W" => "Tryptophan", 
	"Y" => "Tyrosine", 
	"V" => "Valine", 
	"X" => "STOP"
);

REENTER_FASTA:
$consumer -> query("Please enter the full name of your fasta file with the extention...[e.g fasta.txt]\n");
my $fasta = consumeInput(
	["proteinFileName"], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> fasta -> {callback}
	}
);
chomp $fasta;

open(my $fastafile, '<', $cCache -> {path} -> {input} -> ($fasta, "fasta")) 
or $consumer -> {configDefined}
	? $consumer -> err(["Cannot open $fasta"])
	: goto REENTER_FASTA;
my @fasta_array = ();
while (<$fastafile>) {
	$consumer -> {cache} -> {transliterate} -> {lfCr} -> (\$_);
	if (
		$_ =~ /.*[>]+.*/ 
		|| $_ =~ /.*[|.;]+.*/ 
		|| $_ !~ /^[ARNDBCQEZGHILKMFPSTWYVarndbcqezghilkmfpstwyv]+\s*$/
	) {
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
$consumer -> query("Type the cdna file name...[e.g mrna.txt]\n");
$_ = consumeInput(
	["mrnaFileName"], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> mrna -> {callback}
	}
);
chomp $_;
my $cdnafilename = $_;
open(my $cdnafile, '<', $cCache -> {path} -> {input} -> ($cdnafilename, "cdna")) 
or $consumer -> {configDefined}
	? $consumer -> err(["Cannot open $cdnafilename"])
	: goto REENTER_CDNA;
my @cdna_array = ();
while (<$cdnafile>) {
	$consumer -> {cache} -> {transliterate} -> {lfCr} -> (\$_);
	if (
		$_ =~ /.*[>]+.*/ 
		|| $_ =~ /.*[|.;]+.*/ 
		|| $_ !~ /^(\s*[ATCGatcg]+\s*)+$/
	) {
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
	print "Your cDNA exactly matches your fasta file. Continuing...\n";
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



$consumer -> query("What is the name of your protein?[e.g BRCA1]\n");
$_ = consumeInput(
	["name"], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> protein -> {name}
	}
);
chomp $_;
$protein_name = $_;
open(my $karyotypefile, '>', $cCache -> {path} -> {datatracks} -> ("karyotype")) or die "Cannot open the karyotype file!\n";
print "Making karyotype file...\n";
print $karyotypefile "chr - ".$protein_name." ".$protein_name." "."0"." ".$protein_length."000000"." "."vdgrey"."\n";
print "KARYOTYPE::OK\n";


print "Making protein sequence and scatter plots...\n";
open(my $sequencefile, '>', $cCache -> {path} -> {datatracks} -> ("protein_sequence")) or die "Cannot open the sequence file!\n";
open(my $scatterfile, '>', $cCache -> {path} -> {datatracks} -> ("scatter")) or die "Cannot open the scatter file!\n";
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

###############################################################################
##########################CHECK VARIATION PM###################################
my ($missense_counter) = @{renderVar(
	$protein_name, 
	$protein_length,
	$consumer, 
	$configJSON, 
	$cCache, 
	\%degenerate_code, 
	\@fasta_array,
	\@cdna_array
)};
###############################################################################
###############################################################################

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
open(my $modictfile, '>', $cCache -> {path} -> {datatracks} -> ("modict_plot")) or die "Cannot open the modict plot file!\n";
print "Please type in the name of your iterator results in file..\n";
my $iterator_results = <STDIN>;
chomp $iterator_results;
SKIP_MODICT_1:
$consumer -> query("Please type in the name of your conservation file...\n");
my $conservation = consumeInput(
	["conservation","consFileName"], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> conservation -> {callback}
	}
);
$consumer -> {consFile} && chomp $conservation;
if ($modictplot_answer !~ /^y.*/) {
	goto SKIP_MODICT_2;
}
open(my $iteratorfile, '<', $cCache -> {path} -> {input} -> ($iterator_results, "iterator results")) or die "Cannot open the iterator file!\n";
SKIP_MODICT_2:

$consumer -> {consFile} 
&& (
	open(my $conservationfile, '<', $cCache -> {path} -> {input} -> ($conservation, "conservation")) 
	or (
		$consumer -> {configDefined}
		? $consumer -> err([
			"The filename you provided in 'conservation.consFileName'",
			"does not seem to exist."
		])
		: goto SKIP_MODICT_1
	)
);
	
my @iterator_array;
my @conservation_array;
if ($modictplot_answer !~ /^y.*/) {
	goto SKIP_MODICT_3;
}
while (<$iteratorfile>) {
	$consumer -> {cache} -> {transliterate} -> {lfCr} -> (\$_);
	chomp $_;
	push (@iterator_array,$_);
}
SKIP_MODICT_3:

$consumer -> {consFile} && do { 
	while (<$conservationfile>) {
		$consumer -> {cache} -> {transliterate} -> {lfCr} -> (\$_);
		chomp $_;
		push (@conservation_array,$_);
	}
};

my $conservation_min = $consumer -> {consFile} && take_min(@conservation_array);
#the min value can create problems sometimes, print the below line to see if the real mean is picked up.
#print "Your min value is $conservation_min.\n";
my $conservation_max = $consumer -> {consFile} && take_max(@conservation_array);
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
open(my $highlightfile, '>', $cCache -> {path} -> {datatracks} -> ("highlights")) or die "Cannot open the highlights file!\n";
if ($domains[0] > 1) {
	my $i = 0;
	until (($i+2) > $domains[0]) {
		my $element = defined ((\@conservation_array) -> [0]) 
			? shift (@conservation_array) 
			: $consumer -> {consDefVal};
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
			my $element = defined ((\@conservation_array) -> [0]) 
				? shift (@conservation_array) 
				: $consumer -> {consDefVal};
			print $highlightfile $protein_name." ".($domains[$index_array[0]] + $i - 1)*1000000 ." ".($domains[$index_array[0]]+ $i)*1000000 ." type=Domain,conservation=$element,property=$property,svgid=Residue_".(($domains[$index_array[0]] + $i - 1)+1)."_Conservation-Score_$element,svgclass=$property\n";
			$i++;
		}
	} elsif ($index_array[0] != $#domains) {
		my $i = 1;
		until (($domains[$index_array[0]] + $i + 1) > $domains[$index_array[0]+1]) {
			my $element = defined ((\@conservation_array) -> [0]) 
				? shift (@conservation_array) 
				: $consumer -> {consDefVal};
			print $highlightfile $protein_name." ".($domains[$index_array[0]] + $i - 1)*1000000 ." ".($domains[$index_array[0]]+ $i)*1000000 ." type=Coil,conservation=$element,property=n/a,svgid=Residue_".(($domains[$index_array[0]] + $i - 1)+1)."_Conservation-Score_$element\n";
			$i++;
		}
	}
}
if ($domains[$#domains] < $protein_length) {
	my $i = 1;
	until (($domains[$#domains] + $i) > $protein_length) {
		my $element = defined ((\@conservation_array) -> [0]) 
			? shift (@conservation_array) 
			: $consumer -> {consDefVal};
		print $highlightfile $protein_name." ".($domains[$#domains] + $i - 1)*1000000 ." ".($domains[$#domains] + $i)*1000000 ." type=Coil,conservation=$element,property=n/a,svgid=Residue_".(($domains[$#domains] + $i - 1)+1)."_Conservation-Score_$element\n";
		$i++;
	}
}
print "HIGHLIGHTS::OK\n";


$consumer -> query("Would you like to create markup file?[yes/no]\n");
$_ = consumeInput(
	["markups"], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> markup -> {assign}
	}
);
chomp $_;
my $markup_choice = $_;
if ($_ !~ /^y.*/) {
	$markup_choice = "no";
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
open(my $connectorfile, '>', $cCache -> {path} -> {datatracks} -> ("connector")) or die "Cannot open the connector file!\n";
open(my $connector_text_file, '>', $cCache -> {path} -> {datatracks} -> ("connector_text")) or die "Cannot open the connector_text file!\n";
for (my $i = 0; $i < scalar(@markup); $i += 4) {
		print $connectorfile $protein_name." ".($markup[$i+1]+$markup[$i] - 1)/2*1000000 ." ".($markup[$i]-1)*1000000 ." property=".$markup[$i+3]."\n";
		print $connectorfile $protein_name." ".($markup[$i+1]+$markup[$i] - 1)/2*1000000 ." ".($markup[$i+1])*1000000 ." property=".$markup[$i+3]."\n";
		print $connector_text_file $protein_name." ".($markup[$i] - 1)*1000000 ." ".($markup[$i+1])*1000000 ." ".$markup[$i+2]." property=".$markup[$i+3].","."svgclass=connector".","."svgid="."Connector_".$markup[$i]."-".$markup[$i+1]."\n";
}
print "MARKUP::OK\n";
SKIP_CONNECTOR:

print join(
	"\n",
	@{[
		"Your plot files are created under",
		$cCache -> {path} -> {datatracksDir} -> (),
		""
	]}
);

print "Configuring plots.conf file from plots template..\n";
open(my $plotfile, '>', $cCache -> {path} -> {datatracks} -> ("plot")) or die "Cannot write to plot file!\n";
open(my $templatefile, '<', $cCache -> {path} -> {templates} -> ("plots_template")) or die "Cannot open the template file!\n";
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
	if ($_ =~ /^\s*#/) {
		if ($_ =~ /#coil_1/) {
			if ($consumer -> {consFile}) {
				print $plotfile "r1 = eval(qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1)[remap_round(var(conservation),"
					.$conservation_min
					.","
					.$conservation_max
					.",0,9)] .'r')\n";
			} else {
				print $plotfile "r1 = eval("
				."qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1)[" 
				.$consumer -> {consBarHeight}
				."] . 'r')\n";
			}
		} elsif ($_ =~ /#domain_colors/) {
			foreach my $element (keys %domain_colors) {
				my @results= prefixer ($domain_colors{$element});
				if ($consumer -> {consFile}) {
					print $plotfile "<rule>\ncondition = var(type) eq 'Domain' && var(property) eq "
						."'$element'"
						."\n"
						."stroke_color = "
						.$domain_colors{$element}
						."\n"
						."fill_color = "
						.$results[0]
						.$results[1]
						."\n"
						."r1 = eval(qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1)[remap_round(var(conservation),"
						.$conservation_min
						.","
						.$conservation_max
						.",0,9)] .'r')"
						."\n"
						."flow = continue\n</rule>\n";
				} else {
					print $plotfile "<rule>\ncondition = var(type) eq 'Domain' && var(property) eq "
						."'$element'"
						."\n"
						."stroke_color = "
						.$domain_colors{$element}
						."\n"
						."fill_color = "
						.$results[0]
						.$results[1]
						."\n"
						."r1 = eval(qw(1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.1)["
						.$consumer -> {consBarHeight}
						."] . 'r')\n"
						."flow = continue\n</rule>\n";
				}
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
		} elsif ($_ =~ /#has_variations/) {
			print $plotfile "show = " . ($consumer -> {hasVariations} ? "yes" : "no") . "\n";
		}
		next;
	}
	print $plotfile $_;
}
print "Plot file created.\n";
print "Renaming extension.\n";
open($plotfile, '<', $cCache -> {path} -> {datatracks} -> ("plot")) or die "Cannot read from plot file!\n";
copy ($plotfile, $cCache -> {path} -> {datatracks} -> ("plotConf")) or die "$!\n";
$consumer -> query([
	"You can either continue for image generation or run circos yourself.",
	"type 'exit' and enter to quit or press any key and enter to continue.."
]);
my $continue = consumeInput(
	["circos", "run"], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> circos -> {run}
	}
);
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
if ($consumer -> {consFile}) { 
	close $conservationfile or die "$!\n";
}
#close $iteratorfile or die "$!\n";
close $sequencefile or die "$!\n";
close $scatterfile or die "$!\n";
close $karyotypefile or die "$!\n";
close $cdnafile or die "$!\n";
close $fastafile or die "$!\n";
#close file handles

$consumer -> query([
	"Filehandles at datatracks folder are closed.",
	"You can now change these folders before proceeding.",
	"Press enter to continue.."
]);

consumeInput(
	[], 
	$configJSON,
	{
		"ask" => $consumer -> ask,
		"callback" => $consumer -> circos -> {pass}
	}
);

#Run circos
print "Running circos..\n";
my $circos = $cCache -> {path} -> {circos} -> ();
# "C:/strawberry/circos-0.67-7/bin/circos"
my $circos_results = system(
	$^X, 
	$circos, 
	"-conf=" . $cCache -> {path} -> {templates} -> ("circos_templateConf"),
	"-outputdir=" . $cCache -> {path} -> {outputDir} -> ()
);
print "Your image is created..\n";
#Run circos

#Inject javascript
print "Injecting Javascript..\n";
copy(
	$cCache -> {path} -> {outputWithExt} -> ("circos.svg"), 
	$cCache -> {path} -> {outputWithExt} -> ("circos.txt")
) or die "$!\n";
open(my $javascriptfile, '<', $cCache -> {path} -> {templates} -> ("javascript")) or die "Cannot read from javascript template!\n";
open(my $svgtextfile, '<', $cCache -> {path} -> {outputWithExt} -> ("circos.txt")) or die "Cannot read from vector file!\n";
open(my $htmltextfile, '>', $cCache -> {path} -> {outputWithExt} -> ("$protein_name.txt")) or die "Cannot write to html text file!\n";

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
open($htmltextfile, '<', $cCache -> {path} -> {outputWithExt} -> ("$protein_name.txt")) or die "Cannot read from html text!\n";
copy($htmltextfile, $cCache -> {path} -> {outputWithExt} -> ("$protein_name.html")) or die "$!\n";
#Inject javascript

print join(
	"\n",
	@{[
		"Your file $protein_name.html is created under",
		$cCache -> {path} -> {outputDir} -> (),
		""
	]}
);

$consumer -> set("onSuccess", 1);
END {
	my $onFailMsg = join("\n",@{[
		"The script did not complete succesfully.",
		"Some shutdown options like copy\\move will",
		"not be executed.\n"
	]});
	if(!defined $consumer) {
		die $onFailMsg;
	}
	if(!($consumer -> {onSuccess})){
		warn $consumer -> rawMsg($onFailMsg);
	} else {
		my $circosCleanup = consumeInput(
			["circos","cleanup"], 
			$consumer -> {json}
		) || 0;
		if($circosCleanup) {
			$cCache -> {path} -> {cleanFiles} -> (
				[grep {$_ !~ m/\.html$/} @{$cCache -> {path} -> {allOutputs} -> ()}]
			);
		}
		$cCache -> {perms} -> {setPerm} -> (
			$cCache -> {path} -> {allOutputs} -> (),
			$consumer -> {circosOutputPerms}
		);
		$cCache -> {perms} -> {setPerm} -> (
			$cCache -> {path} -> {allDatatracks} -> (),
			$consumer -> {datatracksPerms}
		);
		my $dtTrckCopy = consumeInput(
			["datatracks","copy"], 
			$consumer -> {json}
		) || 0;
		my $dtTrckCleanup = consumeInput(
			["datatracks","cleanup"], 
			$consumer -> {json}
		) || 0;
		my $dtTrckMove = consumeInput(
			["datatracks","move"], 
			$consumer -> {json}
		) || 0;
		#cp is used rather than copy to preseve permissions
		if ($dtTrckCopy && $dtTrckMove ne $dtTrckCopy){
			$cCache -> {path} -> {copyFilesCp} -> (
				$cCache -> {path} -> {allDatatracks} -> (),
				$cCache -> {path} -> {datatracksCustomDir} -> ("copy")
			);
		}
		if ($dtTrckMove) {
			$cCache -> {path} -> {moveFiles} -> (
				$cCache -> {path} -> {allDatatracks} -> (),
				$cCache -> {path} -> {datatracksCustomDir} -> ("move")
			);
		}
		if ($dtTrckCleanup && !$dtTrckMove) {
			$cCache -> {path} -> {cleanFiles} -> (
				$cCache -> {path} -> {allDatatracks} -> ()
			);
		}
	}
}

sub list_creation {
	$domain_count++;
	REDEFINE_1:
	$consumer -> query("Please type the start of domain_$domain_count...[Hint: Enter integer and press enter]\n");
	$_ = consumeInput(
		["domains", 0, "start"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> domain -> {start}
		}
	);
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		$consumer -> err([
			"Few simple rules for entering domains:",
			"1. Only numbers are allowed.",
			"2. Cannot be larger than your protein's aa length.",
			"3. No negative numbers."
		]);
		goto REDEFINE_1;
	}
	if (($#domains >= 1) && ($_ <= $domains[$#domains])){
		$consumer -> err([
			"1. You cannot enter overlaping regions.",
			"2. You cannot enter a value smaller than the end of previous domain.",
			"Hint: If you have overlaping domains in your protein (A and B for instance),",
			"you can enter the name for first domain A_and_B-part1 and the second B-part2.",
			"Use underscores instead of spaces, they will be replaced later on."
		]);
		goto REDEFINE_1;
	}
	my $i = $_;
	push (@domains, $_);
	LC_RETRY:
	$consumer -> query("Please type the end of domain_$domain_count...[Hint: Enter integer and press enter]\n");
	$_ =  consumeInput(
		["domains", 0, "end"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> domain -> {end}
		}
	);
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		$consumer -> err([
			"Few simple rules for entering domains:",
			"1. Only numbers are allowed.",
			"2. Cannot be larger than your protein's aa length.",
			"3. No negative numbers."
		]);
		goto LC_RETRY;
	}
	if (($#domains >= 1) && ($_ <= $domains[$#domains])){
		$consumer -> err([
			"1. You cannot enter overlaping regions.",
			"2. You cannot enter a value smaller than the end of previous domain.",
			"Hint: If you have overlaping domains in your protein (A and B for instance),",
			"you can simply enter the name for first domain A_and_B-part1 and the second B-part2.",
			"Use underscores instead of spaces, they will be replaced later on."
		]);
		goto LC_RETRY;
	}
	my $j = $_;
	if ($j <= $i) {
		$consumer -> err([
			"You cannot enter an equal or smaller value...please retry."
		]);
		goto LC_RETRY;
	}
	push (@domains, $_);
	my $property;
	$consumer -> query([
		"Would you like to assign a property to this domain?",
		"Properties are necessary to attain colors..[yes/no]"
	]);
	$_ = consumeInput(
		["domains"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> domain -> {assign}
		}
	);
	chomp $_;
	if ($_ =~ /^y.*/) {
		$consumer -> query("What would be the name of this property?[e.g X_domain, X-domain]\n");
		REDEFINE_2:
		$_ = consumeInput(
			["domains", 0, "name"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $consumer -> domain -> {name}
			}
		);
		chomp $_;
		if ($_ =~ /\s+|\/+|\\+|[()]+|\[+|\]+/) {
			$consumer -> err([
				"Spaces,slashes or pharanthesis are not allowed.",
				"Use underscores for spaces instead. Please retry:"
			]);
			goto REDEFINE_2;
		}
		$property = $_;
		$consumer -> query([
			"Please enter a color for this region that circos understands..[eg. vdblue, lmagenta, vvdbrown..]",
			"If you see black instead in your output you probably entered an undefined color."
		]);
		$_ = consumeInput(
			["domains", 0, "color"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $consumer -> domain -> {color}
			}
		);
		chomp $_;
		$domain_colors{$property} = $_;
	} else {
		$property = "n/a";
	}
	push (@domain_properties, $property);
	$consumer -> query("Are there more domains in your protein?[yes/no]\n");
	$_ =  consumeInput(
		["domains"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> domain -> {nextDomain}
		}
	);
	chomp $_;
	until (($_ =~ /^n.*/) || ($_ !~ /^y.*/)) {
		list_creation ($_);
	}
}

sub markup {
	$markup_count++;
	REDEFINE_MARKUP_1:
	$consumer -> query([
		"Please type the start of region_$markup_count...",
		"[Hint: Enter integer and press enter]"
	]);
	$_ = consumeInput(
		["markups", 0, "start"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> markup -> {start}
		}
	);
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		$consumer -> err([
			"Few simple rules for entering markups:",
			"1. Only numbers are allowed.",
			"2. Cannot be larger than your protein's aa length.",
			"3. No negative numbers."
		]);
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
	$consumer -> query([
		"Please type the end of region_$markup_count...",
		"[Hint: Enter integer and press enter]"
	]);
	$_ =  consumeInput(
		["markups", 0, "end"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> markup -> {end}
		}
	);
	chomp $_;
	if (($_ !~ /^[1-9]{1}[0-9]*$/) || ($_ > scalar(@fasta_array))) {
		$consumer -> err([ 
			"Few simple rules for entering markups:",
			"1. Only numbers are allowed.",
			"2. Cannot be larger than your protein's aa length.",
			"3. No negative numbers." 
		]);
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
		$consumer -> err("You cannot enter a smaller value than the start..Please retry.\n");
		goto MU_RETRY;
	}
	push (@markup, $_);
	$consumer -> query("What is the name of this region?[e.g Interaction_with_target_X]\n");
	REDEFINE_MARKUP_2:
	$_ = consumeInput(
		["markups", 0, "name"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> markup -> {name}
		}
	);
	chomp $_;
	if ($_ =~ /\s+|\/+|\\+|[()]+|\[+|\]+/) {
		$consumer -> err([
			"Spaces,slashes or pharanthesis are not allowed.",
			"Use underscores for spaces instead.",
			$consumer -> {configDefined} ? "" : "Please retry:"
		]);
		goto REDEFINE_MARKUP_2;
	}
	push (@markup, $_);
	my $property;
	$consumer -> query([
		"Would you like to assign a property to this region?",
		"Properties are necessary to attain colors..[yes/no]"
	]);
	$_ = consumeInput(
		["markups"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> markup -> {assign}
		}
	);
	chomp $_;
	if ($_ =~ /^y.*/) {
		$consumer -> query([
			"What would be the name of this property?",
			"[e.g Interaction_with_target_X]"
		]);
		REDEFINE_MARKUP_3:
		$_ = consumeInput(
			["markups", 0, "prop"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $consumer -> markup -> {prop}
			}
		);
		chomp $_;
		if ($_ =~ /\s+|\/+|\\+|[()]+|\[+|\]+/) {
			$consumer -> err([
				"Spaces,slashes or pharanthesis are not allowed.",
				"Use underscores for spaces instead",
				$consumer -> {configDefined} ? "" : "Please retry:"
			]);
			goto REDEFINE_MARKUP_3;
		}
		$property = $_;
		$consumer -> query([
			"Please enter a color for this markup",
			"that circos understands..[eg. vdblue, lmagenta, vvdbrown..]",
			"If you see black instead in your output,",
			"you probably entered an undefined color."
		]);
		$_ = consumeInput(
			["markups", 0, "color"], 
			$configJSON,
			{
				"ask" => $consumer -> ask,
				"callback" => $consumer -> markup -> {color}
			}
		);
		chomp $_;
		$markup_colors{$property} = $_;
	} else {
		$property = "n/a";
	}
	push (@markup, $property);
	$consumer -> query([
		"Are there more regions that you want",
		"to mark in your protein?[yes/no]"
	]);
	$_ =  consumeInput(
		["markups"], 
		$configJSON,
		{
			"ask" => $consumer -> ask,
			"callback" => $consumer -> markup -> {nextMarkup}
		}
	);
	chomp $_;
	until (($_ =~ /^n.*/) || ($_ !~ /^y.*/)) {
		markup ($_);
	}
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
	if (wantarray) {
		die join(
			"\n",
			@{[
				"take_min should not be expected",
				"to return in list context"
			]}
		);
	}
	my @min;
	my @test_set;
	@test_set = @_;
	if (!scalar(@test_set)){
		return;
	}
	my $i = 0;
	push (@min, $test_set[$i]);
	$i++;
	until ($i == scalar(@test_set)) {
		if ($test_set[$i] !~ /^\s*$/) {
			if ($test_set[$i] < $min[0]) {
				shift (@min);
				push (@min, $test_set[$i]);
			}
		}
		$i++;
	}
	return $min[0];
}

sub take_max {
	if (wantarray) {
		die join(
			"\n",
			@{[
				"take_max should not be expected",
				"to return in list context"
			]}
		);
	}
	my @max;
	my @test_set;
	@test_set = @_;
	if (!scalar(@test_set)){
		return;
	}
	my $i = 0;
	push (@max, $test_set[$i]);
	$i++;
	until ($i == scalar(@test_set)) {
		if ($test_set[$i] !~ /^\s*$/) {
			if ($test_set[$i] > $max[0]){
				shift (@max);
				push (@max, $test_set[$i]);
			} 
		}
		$i++;
	}
	return $max[0];
}

sub getopt {
#Use the getoptions module.
GetOptions ("help=s" => \$help, "version=s" => \$version, "path=s" => \$PATH, "config=s" => \$config) or die ("Once you enter argument press a key and enter to make sure they are defined.\n[Ex: --help h --version v]\n");
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