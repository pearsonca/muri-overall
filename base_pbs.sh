cat > $1 <<EOF
#!/bin/bash
#PBS -r n
#PBS -N bg-clusters-$2
#PBS -o bg-clusters-$2.o
#PBS -e bg-clusters-$2.err
#PBS -m a
#PBS -M cap10@ufl.edu
#PBS -l walltime=4:00:00
#PBS -l nodes=1:ppn=16
#PBS -l pmem=2gb

module load gcc/5.2.0 R/3.2.2
cd /scratch/lfs/cap10/muri-overall
make input/background-clusters/spin-glass/base-$4
EOF
