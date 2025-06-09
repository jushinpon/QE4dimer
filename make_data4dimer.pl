
#!/usr/bin/perl
=b

=cut
use strict;
use warnings;
use Cwd;
use Data::Dumper;
use JSON::PP;
use Data::Dumper;
use List::Util qw(min max);
use Cwd;
use POSIX;
use Parallel::ForkManager;
use lib './';#assign pm dir
use elements;#all setting package
use is_metalCheck qw(is_metal);#check if element is metal
use Math::BigFloat;
my $currentPath = getcwd();
my $store_path = "$currentPath/dimer_data";#store path
my $step = 15;#step of distance
#my $max_distance;
#####################
`rm -rf $store_path`;
`mkdir $store_path`;
###parameters to set first

my @elements = ("Cu","Ag","Al", "P", "C","N","O","H");#base elements for pair
my $json;
{
    local $/ = undef;
    open my $fh, '<', "periodic_table.json" or die "no perodic_table.json in the current path!\n";
    $json = <$fh>;
    close $fh;
}
my $decoded = decode_json($json);
# Use Dumper to inspect the structure
#print Dumper($decoded);


my %radius;

for my $ele (@elements) {
    $radius{$ele} = $decoded->{$ele}->{calculated_radius};#get radius from json
    die "No information of atomic radius of element $ele in perodic_table.json\n" unless ($radius{$ele});
    print "radius of $ele: $radius{$ele}\n";#print radius
}


my @combinations;

for my $i (0 .. $#elements) {
    for my $j (0 .. $#elements) {
        if ($i <= $j) {
            my $is_metal_i = is_metal($elements[$i]);
            my $is_metal_j = is_metal($elements[$j]);
            #print "elements[$i]: $elements[$i], elements[$j]: $elements[$j]\n";
            #print "is_metal_i: $is_metal_i, is_metal_j: $is_metal_j\n\n";
            unless($is_metal_i && $is_metal_j) {#both are not metals
                print "category 1: both are not metals\n";
                print "elements[$i]: $elements[$i], elements[$j]: $elements[$j]\n";
                print "is_metal_i: $is_metal_i, is_metal_j: $is_metal_j\n\n";
                #category 1: 
                my $max_distance = ($radius{$elements[$i]} + $radius{$elements[$j]})*1.5;#longer
                my $radus_sum = ($radius{$elements[$i]} + $radius{$elements[$j]})*0.5;#shorter    
                push @combinations, [$elements[$i], $elements[$j],$radus_sum,$max_distance];
            }
            else{# at least one is metal
                print "category 2: at least one is metal\n";
                print "elements[$i]: $elements[$i], elements[$j]: $elements[$j]\n";
                print "is_metal_i: $is_metal_i, is_metal_j: $is_metal_j\n\n";
                #category 2:  are not metals\n";
                my $max_distance = ($radius{$elements[$i]} + $radius{$elements[$j]})*1.2;#longer
                my $radus_sum = ($radius{$elements[$i]} + $radius{$elements[$j]})*0.3;#shorter    
                push @combinations, [$elements[$i], $elements[$j],$radus_sum,$max_distance];
            }
           
        }
    }
}


# Print combinations
for my $pair (@combinations) {
    print "pair, starting distance and max distance: @$pair\n";
}

for my $ele (@combinations){
    my $ele1 = $ele->[0];
    my $ele2 = $ele->[1];
    my $distance = $ele->[2];
    my $max_distance = $ele->[3];
    my %ntype;
    $ntype{$ele1} = 1;
    $ntype{$ele2} = 1;
    my $ntype = scalar keys %ntype;#number of types

    #my $distance = $ele[2];
    my $increment = ($max_distance - $distance)/$step;#increment of distance

    my @mass;
    for my $m (0 .. $ntype -1){
        my $ele = $ele->[$m];
        my $temp = &elements::eleObj($ele);
        die "No information of element $ele in elements.pm\n" unless ($temp);
        my $mass = ${$temp}[2];
        my $lmp_id = $m + 1;#lmp id starts from 1
        push @mass, "$lmp_id $mass # $ele";
    }
    my $mass = join "\n", @mass;#join mass    

    for my $s (0..$step){
        my $d = $distance + $s * $increment;# x coordinate of atom 2
        my $id = sprintf("%02d", $s + 1);#id of dimer
        my $filename = $ele1 . "_". $ele2 . "_dimer$id.data";
        my %heredoc_para = (
            output_file => "$store_path/$filename",
            mass => $mass,
            ntype => $ntype,
            x_atom2 => $d
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
  
2  atoms
$heredoc_hr->{ntype}  atom types
 
0.000000000000      26.0000000000000  xlo xhi
0.000000000000      12.0000000000000  ylo yhi
0.000000000000      12.0000000000000  zlo zhi
 
Masses
 
$heredoc_hr->{mass} 
 
Atoms 
 
1    1    0.0  0.0  0.0
1    $heredoc_hr->{ntype}  $heredoc_hr->{x_atom2} 0.0  0.0
END_MESSAGE

my $file = $heredoc_hr->{output_file};
open(FH, '>', $file) or die $!;
print FH $hereinput;
close(FH);
}
