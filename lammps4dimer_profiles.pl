use warnings;
use strict;
use JSON::PP;
use Data::Dumper;
use Cwd;
use POSIX;
use lib '.';#assign pm dir for current dir
use elements;#all setting package

my $currentPath = getcwd();
my @DLP_elements = ("Al","P");#make sure your DLP element sequence in data files is the same as this sequence
my $atom_types = join(" ",@DLP_elements);#type map for lammps data files, the order is important, and the first element is 1
my $DLP_path = "/home/jsp1/AlP/dp_train_new/dp_train/graph01/graph-compress01.pb";#trained DLP model path

my $source_path = "$currentPath/DLP_data";#source data files path

my $store_path = "$currentPath/lammps_distance_energy";#data files with DLP type id

`rm -rf $store_path`;
`mkdir $store_path`;

###make slurm file for conducting all lmp jobs
my @string = qq(
#!/bin/sh
#SBATCH --output=lmp4all.out
#SBATCH --job-name=dimer_distance_energy
#SBATCH --nodes=1
#SBATCH --partition=All

hostname

if [ -f /opt/anaconda3/bin/activate ]; then
    
    source /opt/anaconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:\$PATH

elif [ -f /opt/miniconda3/bin/activate ]; then
    source /opt/miniconda3/bin/activate deepmd-cpu-v3
    export LD_LIBRARY_PATH=/opt/deepmd-cpu-v3/lib:/opt/deepmd-cpu-v3/lib/deepmd_lmp:\$LD_LIBRARY_PATH
    export PATH=/opt/deepmd-cpu-v3/bin:\$PATH
else
    echo "Error: Neither /opt/anaconda3/bin/activate nor /opt/miniconda3/bin/activate found."
    exit 1  # Exit the script if neither exists
fi

node=1
threads=\$(nproc)
processors=\$(nproc)
np=\$((\$node*\$processors/\$threads))

export OMP_NUM_THREADS=\$processors
export TF_INTRA_OP_PARALLELISM_THREADS=\$processors
);

map { s/^\s+|\s+$//g; } @string;
my $string = join("\n",@string);

unlink "$store_path/lmp4all.sh";
open(FH1, '>', "$store_path/lmp4all.sh") or die $!;
print FH1 "$string\n";


my @data_files = `find -L $source_path -type f -name "*.data"|grep dimer0.data`;#all QE input
map { s/^\s+|\s+$//g; } @data_files;
#print "data files: @data_files\n";

for my $in (@data_files){
    print "input: $in\n";
    my $path = `dirname $in`;
    my $filename = `basename $in`;
    chomp ($path,$filename);
    
    $filename =~ /(.+)_dimer0\.data$/;#modify it to your own data file name    
    chomp $1;
    my $pair_name = $1;

    my $here_doc =<<"END_MESSAGE";
plugin load libdeepmd_lmp.so #for deepmd-v3 only
# === Read initial data ===
units metal 
dimension 3 
boundary p p p 
atom_style atomic
atom_modify map array
read_data       $filename

# === Define potential (customize for your system) ===
pair_style      deepmd $DLP_path
pair_coeff      * * $atom_types

# === Group atoms ===
group           atom1 id 1
group           atom2 id 2

# === Output settings ===
#variable        dx equal x[2]-x[1]
#variable        dy equal y[2]-y[1]
#variable        dz equal z[2]-z[1]
#variable        dx2 equal v_dx*v_dx
#variable        dy2 equal v_dy*v_dy
#variable        dz2 equal v_dz*v_dz
#variable        r2 equal v_dx2 + v_dy2 + v_dz2
#variable        r  equal sqrt(v_r2)
#variable r equal sqrt((x[2]-x[1])^2 + (y[2]-y[1])^2 + (z[2]-z[1])^2)
#variable dx equal x[2]-x[1]
#variable dy equal y[2]-y[1]
#variable dz equal z[2]-z[1]
#variable dx2 equal \${dx}*\${dx}
#variable dy2 equal \${dy}*\${dy}
#variable dz2 equal \${dz}*\${dz}
variable r2 equal (x[2]-x[1])^2+(y[2]-y[1])^2+(z[2]-z[1])^2
variable r equal sqrt(v_r2)

variable        pe equal pe

fix             1 all nve
thermo          1
thermo_style    custom step v_r v_r2 pe

# === Prepare for loop ===
variable        step loop 10000
variable        deltax equal 0.25
variable        maxdist equal lx/2.0
variable        outfile string "distance_energy.txt"

# Create a file with header
#shell echo "# Distance(\Å)    Energy(eV)" > \${outfile}
print "# Distance(A)    Energy(eV)" file \${outfile} 
# === Loop: move atom 2 and measure ===
label           loop_move
  run 0

  # Append current r and pe to file
  #shell echo "\${r} \$(pe)" >> \${outfile}
    print "\${r} \$(pe)" append \${outfile} 

  # Break loop if distance >= max
  if "\${r} >= \${maxdist}" then "jump SELF end_loop"

  # Move atom 2 in x by deltax
  displace_atoms atom2 move \${deltax} 0.0 0.0 units box

  next          step
  jump          SELF loop_move

label           end_loop
print           "Loop complete. Results saved to \${outfile}."

END_MESSAGE
    `rm -rf $store_path/$pair_name`;
    `mkdir -p $store_path/$pair_name`;#make sure the pair_name dir
    `cp $in $store_path/$pair_name/$filename`;#copy input data file to pair_name dir
    open(FH, "> $store_path/$pair_name/dis_ener_dimer.in") or die $!;
    print FH $here_doc;
    close(FH);

    print FH1 "cd $store_path/$pair_name/;lmp -in dis_ener_dimer.in\n";
    print FH1 "sleep 1\n";
    
}
print FH1 "echo \"ALL JOBS DONE!\"\n";
close(FH1);
system("chmod +x $store_path/lmp4all.sh");
`cd $store_path;sbatch lmp4all.sh`;#submit all lmp
