package is_metalCheck;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(is_metal);

# Define metal elements (based on periodic table groups)
my %metal_elements = map { $_ => 1 } qw(
    Li Be Na Mg Al K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Rb Sr Y Zr Nb
    Mo Tc Ru Rh Pd Ag Cd In Sn Cs Ba Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi
    Fr Ra La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Ac Th Pa U Np Pu Am Cm Bk Cf Es Fm Md No Lr
);

# Subroutine to check if element is a metal
sub is_metal {
    my ($element) = @_;
    return exists $metal_elements{$element} ? 1 : 0;
}

1;
