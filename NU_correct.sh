#!/bin/bash
#$ -S /bin/bash
#$ -o /ifs/loni/faculty/thompson/four_d/Emily/Gotlib/TBM_scripts/log/ -j y



SUBJECT=(021-T2	150-T2	167-T2	171-T2	180-T2	182-T2	185-T2	189-T2	193-T2	202-T2)
subj=${SUBJECT[${SGE_TASK_ID}-1]}
echo ${dirI}${subj}

dirI=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/freesurfer/FS_Convert/${subj}/
dirO=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/NU/

mkdir -p ${dirO}

/ifs/loni/faculty/thompson/four_d/jvillalo/c3d-0.8.2-Linux-x86_64/bin/c3d ${dirI}${subj}_FSmasked.nii.gz -biascorr -o ${dirO}${subj}_masked_T1_nu.nii.gz


