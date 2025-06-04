=b

=cut
use warnings;
use strict;
use JSON::PP;
use Data::Dumper;
use List::Util qw(min max);
use Cwd;
use POSIX;
use Parallel::ForkManager;
use List::Util qw/shuffle/;
use lib './';#assign pm dir
use iso_energy;#energies (eV) of all isolated atoms 

my $ry2eV = 13.605684958731;

my $currentPath = getcwd();
my $filefold = "$currentPath/data2QE";
my $output_fold = "$currentPath/Energy_distance_profiles";
`rm -rf $output_fold`;
`mkdir -p $output_fold`;
#get pairs
my %pairs;

my @all_fold = `find $filefold -maxdepth 1 -mindepth 1 -type d -exec readlink -f {} \\;|sort`;
map { s/^\s+|\s+$//g; } @all_fold;

for my $i (sort @all_fold){
    $i =~ /\/(\w+_\w+)_dimer\d+$/;
    chomp $1;   
    push @{$pairs{$1}}, $i;
}#

# sorting pairs
for my $pair (sort keys %pairs) {
    #sorting directories by dimer number
    @{$pairs{$pair}} = sort {
        ( $a =~ /dimer(\d+)/ )[0] <=> ( $b =~ /dimer(\d+)/ )[0]
    } @{$pairs{$pair}};
}

for my $pair (sort keys %pairs) {
    print "Pair: $pair\n";
    my @elements = split /_/, $pair;
    my $sum_iso_ener = 0;    
    for my $i (@elements){
        chomp $i;
	    my $iso_ener = &iso_energy::eleObj($i);#get isolated energy
	    $sum_iso_ener += $iso_ener;
    }
    print "sum of Isolated energy of $pair: $sum_iso_ener eV\n";
    open my $fh, '>', "$output_fold/$pair.txt" or die "Cannot open file: $!";
    print $fh "# Distance(Å)\tEnergy(eV)\n";#header
    for my $dir (@{$pairs{$pair}}) {
        #print "sorted  Directory: $dir\n";
        my $base = `basename $dir`;
        $base =~ s/^\s+|\s+$//;
        my $file = "$dir/$base.sout";#QE output file
        open my $all ,"< $file" or die "Cannot open file $file: $!";
	    my @all = <$all>;
	    close($all);
        my @totalenergy;
	#if($useFormationEnergy eq "yes"){
		@totalenergy = grep {if(m/^\s*internal energy E=F\+TS\s*=\s*([-+]?\d*\.?\d*)/){
		#@totalenergy = grep {if(m/^\s*!\s*total energy\s*=\s*([-+]?\d*\.?\d*)/){
		$_ = $1*$ry2eV - $sum_iso_ener;}} @all;
        my $energy = $totalenergy[0];#get first line
        $energy =~ s/^\s+|\s+$//g;#remove leading and trailing spaces
        #get distance
        my @temp = `grep -A 2 "ATOMIC_POSITIONS {angstrom}" $dir/$base.in|grep -v "ATOMIC_POSITIONS {angstrom}"`;
        map { s/^\s+|\s+$//g; } @temp;

        my @fields1 = split /\s+/, $temp[0];
        my @fields2 = split /\s+/, $temp[1];

        my $x1 = $fields1[1] // die "Unexpected format for atomic positions";
        my $x2 = $fields2[1] // die "Unexpected format for atomic positions";

        #print join("\n", @temp), "\n";
        #print "x1: $x1, x2: $x2\n";
        my $dis = $x2 - $x1;#distance in angstrom
        if ($dis < 5.0) {
            print $fh sprintf("%.3f\t%.3f\n", $dis, $energy);
        }

        #print $fh "$dis\t$energy\n";#write distance and energy to file
    }
    close $fh;
}

my @txt_files = `find $output_fold -maxdepth 1 -mindepth 1 -type f -name "*.txt" -exec readlink -f {} \\;|sort`;
map { s/^\s+|\s+$//g; } @txt_files;

for my $i (@txt_files){
    my $base = `basename $i`;
    $base =~ s/\.txt//g;#remove .txt
    chomp $base;
    my $dirname = `dirname $i`;
    $dirname =~ s/^\s+|\s+$//g;
    chdir $dirname;
    system("rm -f $base.png");
    #five fitting arguments: input file, pair name (title), output image, rcut_info file, rcut energy criterion to zero
    system("python $currentPath/spline_fitting.py \"$i\" \"$base dimer\" \"$base.png\" \"$base-rcut_info.txt\" 0.01");    
    #system("python $currentPath/LJ_Morse_fitting.py \"$i\" \"$base dimer\" \"$base.png\" ");    
    #system("mv rcut_info.txt $base-rcut_info.txt");    
}   
    
chdir $currentPath;
###summarize all txt files into one
my @rcut_files = `find $output_fold -maxdepth 1 -mindepth 1 -type f -name "*.txt" -exec readlink -f {} \\;|grep "rcut_info" |sort`;
map { s/^\s+|\s+$//g; } @rcut_files;

my %rcut;#distance of energy close to zero
my %rmin;#distance of minimum energy
for my $i (@rcut_files){
    my $base = `basename $i`;
    chomp $base;
    my $pair = $base;#pair name
    $pair =~ s/-rcut_info\.txt//g;#remove .txt
    my $rcut = `grep "rcut (Å):" $i|awk '{print \$3}'`;#get rcut value
    $rcut =~ s/^\s+|\s+$//g;#remove leading and trailing spaces
    #print "rcut: $rcut, $i\n";
    #system("cat $i");#remove rcut_info file
    #die;
    $rcut{$pair} = $rcut;#store rcut value
    my $rmin = `grep "r_min (Å):" $i|awk '{print \$3}'`;#get rmin value
    $rmin =~ s/^\s+|\s+$//g;#remove leading and trailing spaces
    $rmin{$pair} = $rmin;#store rmin value
}

my @sorted_rcutkeys = sort { $rcut{$b} <=> $rcut{$a} } keys %rcut;
my @sorted_rminkeys = sort { $rmin{$b} <=> $rmin{$a} } keys %rmin;

open my $fh, '>', "$output_fold/rcut_summary.txt" or die "Cannot open file: $!";
print $fh "#Rcut (Å) in descending order\n";#header
for my $pair (@sorted_rcutkeys) {
    my $rcut_value = $rcut{$pair};
    print $fh "$pair\t$rcut_value\n";#write pair, rcut and rmin to file
}

print $fh "\n#Rmin (Å) in descending order\n";#header
for my $pair (@sorted_rminkeys) {
    my $rmin_value = $rmin{$pair};
    print $fh "$pair\t$rmin_value\n";#write pair, rcut and rmin to file
}

my $suggested_rcut = $rcut{$sorted_rcutkeys[0]};#get the first rcut value
chomp $suggested_rcut;
my $suggested_rmin = $rmin{$sorted_rminkeys[0]} * 1.2;#get the first rmin value
chomp $suggested_rmin;
print $fh "\n#Suggested rcut (Å) = max_rcut\n";
print $fh "Suggested rcut (Å):" . sprintf("%.2f",$suggested_rcut)."\n";
print $fh "\n#Suggested rmin (Å) = max_rmin * 1.2\n";
print $fh "Suggested rmin (Å): ". sprintf("%.2f",$suggested_rmin)."\n";
print $fh "\n***You need to check the related png files to make sure whether these two values are acceptable!\n";
close $fh;

#combine all png files into one image
my $square_root = floor(sqrt(scalar @sorted_rminkeys));
my $mult_image = $square_root + 1;#number of images in one row
my $image_list = join(' ', map { "$output_fold/$_.png" } @sorted_rminkeys);
my $arrangement = $mult_image . 'x' . $mult_image;#arrangement of images
system("montage $image_list -geometry +2+2 -tile $arrangement $output_fold/combined_images.png");