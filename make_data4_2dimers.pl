
#!/usr/bin/perl
=b

=cut
use strict;
use warnings;
use Cwd;
use Data::Dumper;
use JSON::PP;
use Data::Dumper;
use List::MoreUtils qw(pairwise);
#use List::Util qw(pairwise);
use Cwd;
use POSIX;
use Parallel::ForkManager;
use lib './';#assign pm dir
use elements;#all setting package
use Math::BigFloat;
my $currentPath = getcwd();
my $store_path = "$currentPath/2dimers_data";#store path
#####################
`rm -rf $store_path`;
`mkdir $store_path`;
###coors of atoms of the reference dimer
my $max_distance = 4.0;#max distance of atoms
my $min_distance = 0.9;#min distance of atoms, > bond length
my $step = 10;#step of distance
my $increment = ($max_distance - $min_distance) / $step;#increment of distance


my $bond_length = 0.75;#bond length of first atom
my $half_bond_length = $bond_length/2.0;#bond length of first atom
my @reference_atom1 = (9.0, 9.0, 9.0);#reference atoms
my $atom1 = join ' ', @reference_atom1;#join reference atoms

#my @reference_atom2 = (0.01, 0.76, 10.0);#reference atoms
my @vectorh = ($bond_length, 0.0, 0.0);#bond vector of first atom
my @vectorv = (0.0, 0.0, $bond_length);#vector of first atom
my %vectors = (v => [@vectorv],
                h => [@vectorh]);
              
my @combinations = ("h-v","v-v","h-h");


my $elements = "H";#base elements for pair

 my $ele = "$elements";
    #print "$ele\n";
    my $temp = &elements::eleObj($ele);
    die "No information of element $ele in elements.pm\n" unless ($temp);
    my $mass = ${$temp}[2];

for my $type (@combinations){
    my @ori = split '-', $type;#split type
    my @vector1 = @{$vectors{$ori[0]}};#vector of first atom
    my @vector2 = @{$vectors{$ori[1]}};#vector of second atom
    
    my @atom2= pairwise { $a + $b } @reference_atom1, @vector1;
    my $atom2 = join ' ', @atom2;#join reference atoms

    my @atom3 =  @reference_atom1;
    my @atom4= pairwise { $a + $b } @reference_atom1, @vector2;

    #translate the second dimer (atoms 3 and 4) to the first dimer (atoms 1 and 2)

    if($type eq "h-v"){
        my $v1 = $bond_length + $min_distance;#vector of first atom
        my $v2 = 0.0;#vector of second atom
        my $v3  = - $half_bond_length;#vector of second atom
        my @temp = ($v1, $v2, $v3);#vector of first atom
        @atom3 = pairwise { $a + $b } @atom3, @temp;#vector of first atom
        @atom4 = pairwise { $a + $b } @atom4, @temp;#vector of first atom;
    }elsif($type eq "v-v"){
        my $v1 = $min_distance;#vector of first atom
        my $v2 = 0.0;#vector of second atom
        my $v3  = 0.0;#vector of second atom
        my @temp = ($v1, $v2, $v3);#vector of first atom
        @atom3 = pairwise { $a + $b } @atom3, @temp;#vector of first atom
        @atom4 = pairwise { $a + $b } @atom4, @temp;#vector of first atom;        
    }elsif($type eq "h-h"){
        my $v1 = $bond_length + $min_distance;#vector of first atom
        my $v2 = 0.0;#vector of second atom
        my $v3  = 0.0;#vector of second atom
        my @temp = ($v1, $v2, $v3);#vector of first atom
        @atom3 = pairwise { $a + $b } @atom3, @temp;#vector of first atom
        @atom4 = pairwise { $a + $b } @atom4, @temp;#vector of first atom;        
    }
    
   
    for my $step (0 .. $step){
        my $distance = $step * $increment;
        my @temp_vec = ($distance, 0.0, 0.0);#vector to move
        my @temp_atom3 = pairwise { $a + $b } @atom3, @temp_vec;#vector of first atom
        my $atom3 = join ' ', @temp_atom3;#join reference atoms
        my @temp_atom4 = pairwise { $a + $b } @atom4, @temp_vec;#vector of map {$_ * $distance} @{$combinations{$type}};#first atom
        my $atom4 = join ' ', @temp_atom4;#join reference atoms

        my $filename = "dimers_$type-$step-". $ele . ".data";
        my %heredoc_para = (
            output_file => "$store_path/$filename",
            mass => $mass,
            element => $ele,
            atom1 => $atom1,
            atom2 => $atom2,
            atom3 => $atom3,
            atom4 => $atom4
            );

        &heredoc(\%heredoc_para);      

    }
         
}


######here doc for lmp data file##########
sub heredoc
{

my ($heredoc_hr) = @_;

my $hereinput = <<"END_MESSAGE";
# "template"
  
4  atoms
1  atom types
 
0.000000000000      20.1000000000000  xlo xhi
0.000000000000      20.1000000000000  ylo yhi
0.000000000000      20.1000000000000  zlo zhi
 
Masses
 
1   $heredoc_hr->{mass} # $heredoc_hr->{element}
 
Atoms 
 
1    1    $heredoc_hr->{atom1} 
2    1    $heredoc_hr->{atom2} 
3    1    $heredoc_hr->{atom3} 
4    1    $heredoc_hr->{atom4}
END_MESSAGE

my $file = $heredoc_hr->{output_file};
open(FH, '>', $file) or die $!;
print FH $hereinput;
close(FH);
}
