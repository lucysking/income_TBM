#!/bin/bash
#$ -S /bin/bash
#$ -o /ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/TBM_2018/Scripts/log/ -j y

export LD_LIBRARY_PATH="/usr/local/gcc-4.2.2_64bit/lib64:/usr/local/gcc-4.2.2_64bit/lib:$LD_LIBRARY_PATH"
export FSLDIR="/usr/local/fsl-4.1.5_64bit"
. ${FSLDIR}/etc/fslconf/fsl.sh


## T1-T2 subs
SUBJECT=(036	102	125)



subj=${SUBJECT[${SGE_TASK_ID}-1]}


RAWDIREC=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/TBM_2018/NU/
#Pretest
DIREC=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/TBM_2018
#Posttest
POSTDIREC=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/TBM_2018/Longitudinal

mkdir -p ${POSTDIREC}/linear_reg_flirt/
mkdir -p ${POSTDIREC}/linear_reg_flirt/${subj}
 
## This is the MDT template - use this
TMPL=/ifs/loni/faculty/thompson/four_d/Emily/Gotlib/ELS/MDT/ENGM_MDT_4step.nii.gz

# T1-T2 registration ##
 
 echo Part II-register posttest scans to match the pretest scan and to ICBM space - longitudinal
 
 echo "flirt -lsq6 posttest to pretest"
 /usr/local/fsl-4.1.5_64bit/bin/flirt -in ${RAWDIREC}${subj}-T2_masked_T1_nu.nii.gz -ref ${RAWDIREC}${subj}-T1_masked_T1_nu.nii.gz -out ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.nii -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.mat  -cost mutualinfo  -interp trilinear -dof 6
 
 echo "flirt -lsq7 posttest to pretest"
 /usr/local/fsl-4.1.5_64bit/bin/flirt -in ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.nii -ref ${RAWDIREC}${subj}-T1_masked_T1_nu.nii.gz -out ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.nii -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.mat  -cost mutualinfo  -interp trilinear -dof 7 
  
 echo "flirt -lsq9 posttest to pretest"
 /usr/local/fsl-4.1.5_64bit/bin/flirt -in ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.nii -ref ${RAWDIREC}${subj}-T1_masked_T1_nu.nii.gz -out ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.nii -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.mat  -cost mutualinfo  -interp trilinear -dof 9 
 
 echo "flirt -lsq12 posttest to pretest"
 /usr/local/fsl-4.1.5_64bit/bin/flirt -in ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.nii -ref ${RAWDIREC}${subj}-T1_masked_T1_nu.nii.gz -out ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq12_flirt.nii -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq12_flirt.mat  -cost mutualinfo  -interp trilinear -dof 12 

#Resample the posttest image to the ICBM space 
#posttest-icbm9p
/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq67p_flirt.mat -concat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq7_flirt.mat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq6_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq679p_flirt.mat -concat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq9_flirt.mat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq67p_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt.mat -concat ${DIREC}/linear_reg_flirt/${subj}-T1/${subj}-T1_combo9p_flirt.mat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq679p_flirt.mat 

/usr/local/fsl-4.1.5_64bit/bin/flirt -in  ${RAWDIREC}${subj}-T2_masked_T1_nu.nii.gz -ref ${TMPL} -applyxfm -init ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt.mat -out ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt_nii.nii -datatype short

/usr/local/fsl-4.1.5_64bit/bin/fslchfiletype ANALYZE ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt_nii.nii ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm9p_flirt.hdr

#posttest-icbm12p
/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq67912p_flirt.mat -concat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq12_flirt.mat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq679p_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/convert_xfm -omat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt.mat -concat ${DIREC}/linear_reg_flirt/${subj}-T1/${subj}-T1_combo12p_flirt.mat ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_lsq67912p_flirt.mat

/usr/local/fsl-4.1.5_64bit/bin/flirt -in  ${RAWDIREC}${subj}-T2_masked_T1_nu.nii.gz -ref ${TMPL} -applyxfm -init ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt.mat -out ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt_nii.nii -datatype short

/usr/local/fsl-4.1.5_64bit/bin/fslchfiletype ANALYZE ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt_nii.nii ${POSTDIREC}/linear_reg_flirt/${subj}/${subj}_icbm12p_flirt.hdr

