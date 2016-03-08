cat > $1 <<EOF
#!/bin/bash
#PBS -r n
#PBS -N bg-pc-$2
#PBS -o bg-pc-$2.o
#PBS -e bg-pc-$2.err
#PBS -m a
#PBS -M cap10@ufl.edu
#PBS -l walltime=24:00:00
#PBS -l nodes=1:ppn=1
#PBS -l pmem=2gb

module load gcc/5.2.0 R/3.2.2
cd /scratch/lfs/cap10/muri-overall
tar=\$(printf 'input/background-clusters/spin-glass/pc-$2/%03d.rds' \$PBS_ARRAYID)
make \$tar
EOF
