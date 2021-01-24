# HCP-fmriprep

[fmriprep](https://www.nature.com/articles/s41592-018-0235-4) is an suscesfull tool to preprocessing fmri data before statistical analysis developed by the Poldrack lab. This tool performs a bunch of steps from differents softwares such as coregistration, normalization, unwarping, noise component extraction, segmentation, skullstripping, etc. Please check the main page to more information [Go to fmriprep](https://fmriprep.org/en/stable/)

![intro](fmriprep-workflow-all.png)

## How to run it 🚀

You can run fmriprep by installing in your computer through python pip, however, you also have to install all the [dependencies to run it](https://fmriprep.org/en/stable/installation.html#external-dependencies)

```
python -m pip install fmriprep
```

However, we strongly recommend to run it using a container ([Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/)). In here, we going to use Singularity to run it in a HCP cluster (Ada-lavis in UNAM). To see what a container is, please check: https://www.docker.com/resources/what-container


### Requirements 📋

We firstly need to create a singularity container from fmriprep. We can copy from the docker container at https://hub.docker.com/r/poldracklab/fmriprep/ and create the singularity one by run the follow command on a terminal in the location of your preference.

```
singularity build fmriprep_v20.sif docker://poldracklab/fmriprep
```

This will create the container file (.sif) with all the dependencies needed

## Configuration before run 🔧

### BIDS format

Remenber, fmriprep requires that the input data are organized according to the [BIDS standard](https://bids.neuroimaging.io/). Please check https://github.com/psilantrolab/Documentation/wiki/Dicom-to-BIDS to check how to convert files in the format.
```
data/bids/
├── CHANGES
├── dataset_description.json
├── LICENSE
├── participants.json
├── participants.tsv
├── README
├── README.md
├── sub-001
│   ├── anat
│   │   ├── sub-001_T1w.json
│   │   └── sub-001_T1w.nii.gz
│   ├── fmap
│   │   ├── sub-001_dir-PA_epi.json
│   │   └── sub-001_dir-PA_epi.nii.gz
│   └── func
│       ├── sub-001_task-rest_bold.json
│       └── sub-001_task-rest_bold.nii.gz
├── sub-002
│   ├── anat
│   │   ├── sub-002_T1w.json
│   │   └── sub-002_T1w.nii.gz
│   ├── fmap
│   │   ├── sub-002_dir-PA_epi.json
│   │   └── sub-002_dir-PA_epi.nii.gz
│   └── func
│       ├── sub-002_task-rest_bold.json
│       └── sub-002_task-rest_bold.nii.gz
```

### Preparing the environment 

In an HCP cluster like ADA, you firstly must load the modules that are needed to start running each tool like singularity.

```
module load singularityce/3.5.3
```

Also you going to need a FreeSurfer license and export it into your script or before run it, but don't worry, it's free: https://surfer.nmr.mgh.harvard.edu/registration.html

```
export FS_LICENSE=$DIR/jrasgado/license.txt
```

## Now we can run it ⚙️

### Single subject run

*The following script will take the location in which you are and ask for some inputs

```
#!/bin/bash

echo "Please enter the subject ID (example: sub-042)"
read sub
echo "running subject $sub"

DIR=$(PWD)
export FS_LICENSE=$DIR/jrasgado/license.txt
container=$DIR/public/singularity_images/fmriprep_v20.sif
outdir=$DIR/output_fmriprep
indir=$DIR/data

singularity run -B /mnt:/mnt \
    $container \
    $inpdir/bids \
    $outdir \
    participant \
    --participant-label ${sub} \
    --skip_bids_validation \
    --resource-monitor \
    --write-graph \
    --work-dir $DIR/tmp/output_fmriprep \
    --output-spaces T1w MNI152NLin2009cAsym fsaverage5 \
    --fd-spike-threshold 0.5 \
    --use-syn-sdc
```

Directly from computer node you can bash the script with:

```
bash fmriprep_script_1s.sh
```

-------

Each parameter in here are taken and can be checked in: https://fmriprep.org/en/stable/usage.html

- participant_label: input for the participant identifier
- output-spaces: Standard and non-standard spaces to resample anatomical and functional images to
- resource-monitor: enable Nipype’s resource monitoring to keep track of memory and CPU usage
- write-graph: Write workflow graph
- fd-spike-threshold: Threshold for flagging a frame as an outlier on the basis of framewise displacement (for patients at 0.5)
- fs-no-reconall: disable FreeSurfer surface preprocessing.
- skip_bids_validation: if you don't have all bids parameters you can skip it

### Run it in a loop cycle

To avoid run each subject one by one, you can create an script to run 'em all without any entry in the terminal.

```
#!/bin/bash

read sub

DIR=/path/to/all/files
export FS_LICENSE=$DIR/jrasgado/license.txt
container=$DIR/public/singularity_images/fmriprep_v20.sif

# I like to send each job using fsl_sub
export FSLDIR=/mnt/MD1200A/user/user/fsl_5.0.6
export PATH=${FSLDIR}/bin:${PATH}
. ${FSLDIR}/etc/fslconf/fsl.sh
export FSLPARALLEL=1
export LD_LIBRARY_PATH=${FSLDIR}/lib:${LD_LIBRARY_PATH}

subjid=`ls -d $DIR/bids/sub-*`

for s in $subjid
do
  this_subject=`basename $s`
  this_subject=${this_subject/sub-/}
  echo "submitting job for subject $this_subject"
  fsl_sub -s openmp,8 -R 10 -N cpr_${this_subject}_fsr \
  singularity run -B /mnt:/mnt $container \
  ${DIR}/data/bids \
  ${DIR}/derrivatives/fmriprep/output_22JAN2021_fsr \
  participant \
  --participant_label $this_subject \
  --output-spaces T1w MNI152NLin2009cAsym fsaverage5\
  --work-dir ${DIR}/tmp/fmriprep/output_22JAN2021_fsr/ \
  --resource-monitor \
  --write-graph \
  --fd-spike-threshold 0.5 \
  --use-syn-sdc

echo ""
sleep 5m

done
```

*you can add "-M jalil.rasgadoto@gmail.com -m ea" after fsl_sub to receive a message of complete or error

and then run it by

```
bash fmriprep_script.sh
```

and that's all folks

## Output 🔩 📦

1) Visual QA (quality assessment) reports: (check one example in: https://fmriprep.org/en/stable/_static/sample_report.html)
*fMRIPrep outputs summary reports, written to <output dir>/fmriprep/sub-<subject_label>.html*. These reports provide a quick way to make visual inspection of the results easy.   

2) Derivatives (preprocessed data):
*Preprocessed, or derivative, data are written to <output dir>/fmriprep/sub-<subject_label>/.*

```
sub-<subject_label>/
  anat/
    sub-<subject_label>[_space-<space_label>]_desc-preproc_T1w.nii.gz
    sub-<subject_label>[_space-<space_label>]_desc-brain_mask.nii.gz
```

*Spatially-standardized derivatives are denoted with a space label*

```
sub-<subject_label>/
  anat/
    sub-<subject_label>_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
    sub-<subject_label>_space-fsaverage5_desc-preproc_T1w.nii.gz
```

*If FreeSurfer reconstructions are used, the following surface files are generated:*

```
sub-<subject_label>/
  anat/
    sub-<subject_label>_hemi-[LR]_smoothwm.surf.gii
    sub-<subject_label>_hemi-[LR]_pial.surf.gii
 ```   

3) Confounds:
Confounds (or nuisance regressors) are variables representing fluctuations with a potential non-neuronal origin. Such non-neuronal fluctuations may drive spurious results in fMRI data analysis, including standard activation GLM and functional connectivity analyses.

![confo](https://fmriprep.org/en/stable/_images/sub-01_task-mixedgamblestask_run-01_bold_carpetplot.svg)

## Monitoring

You can check the status of the job using qstat on terminal

```
job-ID  prior   name       user         state submit/start at     queue                          slots ja-task-ID
-----------------------------------------------------------------------------------------------------------------
  14815 0.50817 fmriprep   jrasgado       r   23/01/2021 16:28:19 all.q@compute-00-10.cm.cluster   3       1
```
## Wiki 📖

You can find more information and others tutorials at [PSILANTRO](https://github.com/psilantrolab/Documentation/wiki/)

## Other Links  ✒️

- Another way to run it: https://github.com/GarzaLab/Documentation/wiki/FMRIPREP-preprocessing

