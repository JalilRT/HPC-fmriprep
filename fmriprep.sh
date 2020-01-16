#!/bin/bash

h=`hostname`
correct_host=naica2

if [[ "$h" = "$correct_host" ]]
then
  echo "OK: Running on host $h"
else
  echo "ERROR: This script has to run on LAVIS on host $correct_host"
  echo "       Currently on host $h"
  echo "       Bye."
  exit 2
fi

export FS_LICENSE=/mnt/MD1200B/giordano/jrasgado/license.txt
container=/mnt/MD1200B/giordano/jrasgado/poldracklab_fmriprep_latest-2019-07-25-ca0e3df498c8.img

export FSLDIR=/mnt/MD1200A/lconcha/lconcha/fsl_5.0.6
export PATH=${FSLDIR}/bin:${PATH}
. ${FSLDIR}/etc/fslconf/fsl.sh
export FSLPARALLEL=1
export LD_LIBRARY_PATH=${FSLDIR}/lib:${LD_LIBRARY_PATH}

subjid=`ls -d /mnt/MD1200B/giordano/jrasgado/EmocionesAH/Nifti/sub-18[2-3][0-9]`

for s in $subjid
do
  this_subject=`basename $s`
  this_subject=${this_subject/sub-/}
  echo "submitting job for subject $this_subject"
  fsl_sub -M jalil.rasgadoto@gmail.com -m ea -s openmp,8 -R 10 -N guera_$this_subject singularity run --bind /mnt $container \
  /mnt/MD1200B/giordano/jrasgado/EmocionesAH/Nifti \
  /mnt/MD1200B/giordano/jrasgado/EmocionesAH/derivates \
  participant \
  --participant_label $this_subject \
  --ignore fieldmaps \
  --output-spaces MNI152NLin2009cAsym anat fsaverage5 -w /mnt/MD1200B/giordano/jrasgado/EmocionesAH/derivates-in \
  --resource-monitor \
  --write-graph --return-all-components
echo ""
done

