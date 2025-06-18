use warnings;
use strict;
use JSON::PP;
use Data::Dumper;
use Cwd;
use POSIX;
use lib '.';#assign pm dir for current dir
use elements;#all setting package

my @DLP_elements = ("Al","P");#your DLP element sequence

my $source_path = "/home/jsp1/AlP/QE4dimer/dimer_data";#source data files path

my $currentPath = getcwd();
my $store_path = "$currentPath/DLP_data";#data files with DLP type id

`rm -rf $store_path`;
`mkdir $store_path`;

#convert DLP elements to lammps type map
my @typemap = @DLP_elements;#type map for lammps data files, the order is important, and the first element is 1
map { s/^\s+|\s+$//g; } @typemap;
#for lammps type id
my %ele2id = map { $typemap[$_] => $_ + 1  } 0 .. $#typemap;
#modify all data files when merging all systems
my $atom_types = @typemap;

#get masses for lammps data file
#get masses for data files
my $mass4data;
my $counter = 1;
for my $e (0..$#typemap) {        
    my $ele = $typemap[$e];
    my $mass = &elements::eleObj("$ele")->[2];
    $mass4data .= $e+1 . " $mass  \# $ele\n";           
}
chomp $mass4data;#move the new line for the last line

my @data_files = `find -L $source_path -type f -name "*.data"`;#all QE input
map { s/^\s+|\s+$//g; } @data_files;

for my $in (@data_files){
    print "input: $in\n";
    my $path = `dirname $in`;
    my $filename = `basename $in`;
    chomp ($path,$filename);

    my $natom = `egrep " atoms" $in|awk '{print \$1}'`;#check atom number in QE input. atom number <=1 is not allowed
    $natom =~ s/^\s+|\s+$//;#remove beginnig and end empty space
    my $ori_types = `egrep " atom types" $in|awk '{print \$1}'`;#check atom type number in original data file
    $ori_types =~ s/^\s+|\s+$//;#remove beginnig
    my @ori_types4masses = `cat $path/$filename|grep -v '^[[:space:]]*\$'|egrep "Masses" -A $ori_types|grep -v Masses|grep -v -- '--'|awk '{print \$NF}'`;#get original 
    map { s/^\s+|\s+$//g; } @ori_types4masses;
    die "No element symbols in $path/$filename!\n" unless(@ori_types4masses);
    my @elem = @ori_types4masses;#get element symbols from original data

   #$elem
    #get cell
    my @lmp_cell = `cat $path/$filename|egrep "xlo|ylo|zlo|xy"`;#"[xlo|ylo|zlo|xy]"`;#|grep -v Atoms|grep -v -- '--'`;
    die "No cell information of $path/$filename for $in" unless(@lmp_cell);
    map { s/^\s+|\s+$//g; } @lmp_cell;
    unless($lmp_cell[3]){$lmp_cell[3] = "0.0000 0.0000 0.0000 xy xz yz";}
    my $lmp_cell = join("\n",@lmp_cell);
    chomp $lmp_cell;
    #print "\$lmp_cell: $lmp_cell\n end\n";
    #die; 

    #system("cat $in");
    my @lmp_coors = `cat $path/$filename|grep -v '^[[:space:]]*\$'|grep -A $natom Atoms|grep -v Atoms|grep -v -- '--'`;
    die "No ccords in $path/$filename\n" unless(@lmp_coors);
    map { s/^\s+|\s+$//g; } @lmp_coors; 
    #print join("\n",@lmp_coors),"\n";
    my $coords4data;
    for my $e (0..$#lmp_coors) {
        my @tempcoords = split (/\s+/,$lmp_coors[$e]);
        map { s/^\s+|\s+$//g; } @tempcoords;
        my $array_id = $tempcoords[1] - 1;
        #print "element: $elem[$array_id], coor: $lmp_coors[$e], lmp id: $ele2id{$elem[$array_id]}\n";
        $tempcoords[1] = $ele2id{$elem[$array_id]} ;#change original type id to DLP type id here!
        my $temp = join(" ",@tempcoords);
        $coords4data .= "$temp\n";      
    }
    chomp $coords4data;
    #print "$coords4data\n";
#    die;
# modify data file

    my $here_doc =<<"END_MESSAGE";
# $in

$natom atoms
$atom_types atom types

$lmp_cell

Masses

$mass4data

Atoms  # atomic

$coords4data
END_MESSAGE

    open(FH, "> $store_path/$filename") or die $!;
    print FH $here_doc;
    close(FH);
    
}
