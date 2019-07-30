#!/bin/bash
#$ -S /bin/bash
#$ -o /ifs/loni/faculty/thompson/four_d/Emily/Gotlib/TBM_scripts/log/ -j y

export LD_LIBRARY_PATH="/usr/local/gcc-4.2.2_64bit/lib64:/usr/local/gcc-4.2.2_64bit/lib:$LD_LIBRARY_PATH"
export FSLDIR="/usr/local/fsl-4.1.5_64bit"
. ${FSLDIR}/etc/fslconf/fsl.sh


SUBJECT=(021-T2	150-T2	167-T2	171-T2	180-T2	182-T2	185-T2	189-T2	193-T2	202-T2)

subj=${SUBJECT[${SGE_TASK_ID}-1]}


RAWDIREC=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/TBM_2018/NU/
#Pretest
DIREC=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/TBM_2018

mkdir -p ${DIREC}/linear_reg_flirt/
mkdir -p ${DIREC}/linear_reg_flirt/${subj}


#This is the ICBM brain template
TMPL=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/MDT/ENGM_MDT_4step.nii.gz

echo Part I-register pretest scans to match the ICBM brain template or TMPL - cross-sectional

echo "flirt -lsq6 pretest to ICBM"
/usr/local/fsl-4.1.5_64bit/bin/flirt -in ${RAWDIREC}/NU/${subj}_masked_T1_nu.nii.gz -ref ${TMPL} -out ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.nii -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.mat  -cost mutualinfo  -interp trilinear -dof 6 

echo "flirt -lsq7 pretest to ICBM"
/usr/local/fsl-4.1.5_64bit/bin/flirt -in ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.nii -ref ${TMPL} -out ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.nii -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.mat  -cost mutualinfo  -interp trilinear -dof 7 

echo "flirt -lsq9 pretest to ICBM"
/usr/local/fsl-4.1.5_64bit/bin/flirt -in ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.nii -ref ${TMPL} -out ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.nii -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.mat  -cost mutualinfo  -interp trilinear -dof 9 

echo "flirt -lsq12 pretest to ICBM"
/usr/local/fsl-4.1.5_64bit/bin/flirt -in ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.nii -ref ${TMPL} -out ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq12_flirt.nii -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq12_flirt.mat  -cost mutualinfo  -interp trilinear -dof 12 

#Resample the pretest image to the ICBM space 
#pretest-icbm9p#
/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq67p_flirt.mat -concat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.mat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_combo9p_flirt.mat -concat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.mat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq67p_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/flirt -in  ${RAWDIREC}/NU/${subj}_masked_T1_nu.nii.gz -ref ${TMPL} -applyxfm -init ${DIREC}/linear_reg_flirt/${subj}/${subj}_combo9p_flirt.mat -out ${DIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt_nii.nii -datatype short

/usr/local/fsl-4.1.5_64bit/bin/fslchfiletype ANALYZE ${DIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt_nii.nii ${DIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt.hdr

#pretest-icbm12p#
/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${DIREC}/linear_reg_flirt/${subj}/${subj}_combo12p_flirt.mat -concat ${DIREC}/linear_reg_flirt/${subj}/${subj}_lsq12_flirt.mat ${DIREC}/linear_reg_flirt/${subj}/${subj}_combo9p_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/flirt -in  ${RAWDIREC}/NU/${subj}_masked_T1_nu.nii.gz -ref ${TMPL} -applyxfm -init ${DIREC}/linear_reg_flirt/${subj}/${subj}_combo12p_flirt.mat -out ${DIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt_nii.nii -datatype short

/usr/local/fsl-4.1.5_64bit/bin/fslchfiletype ANALYZE ${DIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt_nii.nii ${DIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt.hdr


