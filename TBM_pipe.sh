#!/bin/bash

source "/ifshome/jfaskow/scripts_cp/ANTS_STUFF/pipeline_attempt/pANTs_config.sh"
antsRegistration="${ANTSPATH}/antsRegistration"

#get script name
script_name=$(basename $0)

reportMappingParameters() {
    cat <<REPORTMAPPINGPARAMETERS
--------------------------------------------------------------------------------------
 Mapping parameters
--------------------------------------------------------------------------------------
 $USER is calling the pANTs (pipeline ANTs) written by Josh Faskowitz 
 *edited by Emily
 with this script: $script_name

 ANTSPATH is $ANTSPATH

 Dimensionality:           $dim 
 Output name prefix:       ${output_call}
 Fixed images:             $fixed_image
 Moving images:            $moving_image
 Image to apply to:        $image_to_apply_to

 Transform type:           ${transform_call}
 Convergence:              ${convergence_call}
 Similarity Metric:        ${metric}
 Smoothing Sigmas:         $smooth_sigmas
 Shrink Factors:           $shrink_factors

 Use histogram matching    $use_histogram_matching
 Write Composite Trans:    $write_coposite_transform
 Winsorize Intensity:      $winsorize_intensity
 Constrain dir(XYZ):       $constrain_z_direction
 
======================================================================================

REPORTMAPPINGPARAMETERS
}

#user input variables
dim=3
fixed_image=
moving_image=
output_prefix=
image_to_apply_to=''

convergence=
transform=
metric=
smooth_sigmas=
shrink_factors=

write_composite_transform=0
use_histogram_matching=
constrain_z_direction=
winsorize_intensity=


#Check the number of arguments. If none are passed, print help and exit.
NUMARGS=$#
echo -e \\n"Number of arguments: $NUMARGS"
if [ $NUMARGS -eq 0 ]; then
	echo -e "\nNot enough args yo."
	exit 1
fi

while getopts "r:i:w:m:c:s:f:u:y:o:z:t:a:" OPTION
do
     case $OPTION in
	
		r)
			fixed_image=$OPTARG
			;;
		i)
			moving_image=$OPTARG
			;;
		w)
			write_composite_transform=$OPTARG
			;;
		m)
			metric=$OPTARG
			;;
		c)
			convergence=$OPTARG
			;;
		s)
			smooth_sigmas=$OPTARG
			;;
		f)
			shrink_factors=$OPTARG
			;;
		u)
			use_histogram_matching=$OPTARG
			;;
		y)
			if [ $OPTARG == "1" ] ; then 
				constrain_z_direction='1x1x0'
			else
				constrain_z_direction='1x1x1'
			fi
			;;
		z)
			if [ $OPTARG == "1" ] ; then
				winsorize_intensity='[0.01,0.99]'
			fi
 			;;
		o)
			output_prefix=$OPTARG
			;;
		t)
			transform=$OPTARG
			;;
		a)
			image_to_apply_to=$OPTARG
			;;
     esac
done

shift "$((OPTIND-1))" # Shift off the options and optional --.

if [[ ! -f ${fixed_image} ]] ; then
	echo -e "\nFixed image does not exist. Try again."
	exit 1
fi

if [[ ! -f ${moving_image} ]] ; then
	echo -e "\nmoving image does not exist. Try again."
	exit 1
fi

if [[ ${image_to_apply_to^^} == "NONE" ]] ; then 
	echo ""
elif [[ ! -f ${image_to_apply_to} ]] && [[ -n ${image_to_apply_to} ]] ; then
	echo -e "\nImage to apply to does not exist or is corrupt or I can't read it.  Try again."
	exit 1 
fi

#check to see if the inputs have qform code
moving_qform_code=$(${ANTSPATH}/PrintHeader $moving_image |  awk '/qform_code/ {print $3}')
fixed_qform_code=$(${ANTSPATH}/PrintHeader $fixed_image |  awk '/qform_code/ {print $3}')
apply_qform_code=1
if [[ -n "${image_to_apply_to}" ]] && [[ ${image_to_apply_to^^} != "NONE" ]] 
then 
	apply_qform_code=$(${ANTSPATH}/PrintHeader ${image_to_apply_to} |  awk '/qform_code/ {print $3}')
else
	#we set this just so it does not error out
	apply_qform_code=1
fi

if [[ $moving_qform_code -eq 0 ]] || [[ $fixed_qform_code -eq 0 ]] || [[ ${apply_qform_code} -eq 0 ]] ; then 
	echo -e "\nYour images need to have a qform code specified. \
Meaning it cannot be 0.\n Be careful when messing with this.\n \
But it looks like you are going to have to mess with this."
	exit 1
fi

#formulate the call to the metric
if [[ ${metric} == CC[* ]]; then 
	metric_val=$(echo ${metric} | sed 's/[^0-9]*//g')
	metric=$(echo ${metric%[*})
	metric_call="${metric}[${fixed_image},${moving_image}, 1, ${metric_val}]"
elif [[ ${metric} == MI[* ]]; then 
	metric_val=$(echo ${metric} | sed 's/[^0-9]*//g')
	metric=$(echo ${metric%[*})
	metric_call="${metric}[${fixed_image},${moving_image}, 1, ${metric_val}]"
else 
	metric_call="${metric}[${fixed_image},${moving_image}"
	if [[ ${metric} == 'CC' ]]; then 
		metric_call="${metric_call}, 4]"
	elif [[ ${metric} == 'MI' ]]; then 
		metric_call="${metric_call}, 32]"
	else 
		#this will be the call for GC, Demons, and MeanSquares 
		metric_call="${metric_call}]"
	fi
fi

#now time for the transfrom call (this is totally useless but good programming practice for me
#build from the top
transform_call=${transform%[*}
transform_for_log=${transform%[*}
if [ "${transform_call}" != "${transform}" ]; then 
	number_of_fields=$(echo ${transform#${transform%[*}} | tr -d "[] " | awk -F',' '{print NF}')
	transform_call=${transform_call}"["
	trans_vals=($(echo ${transform#${transform%[*}} | tr -d "[]" | sed s/,/\ /g ))
	for (( i = 0 ; i < "${#trans_vals[@]}" ; i++ )) ; do 
		transform_call=${transform_call}"${trans_vals[$i]}"","
	done
	#now strip the last "," and add a "]"
	transform_call=${transform_call%,}"]"
elif [[ ${transform_call^^} == "SYN" ]] ; then
	transform_call="SyN[0.2,3,0]"
else
	echo -e "\nIn the transform metric call, please specifc \
paramters. \nYour insufficient call was: ${transform} \
\nYou should probably change that."
fi

#now build the convergence call
convergence_call=${convergence%[*}
if [ "$convergence_call" != "${convergence}" ]; then
	convergence_call="${convergence}"
else
	convergence_call="[${convergence},1e-6,5]"
fi

#handle the output option.
#dirpath=$(dirname $output_prefix)"/"
dirpath=${output_prefix%/*}"/"
pre_string=
if [ ${dirpath} == ${output_prefix} ]; then 
	pre_string="output_"
else
	pre_string=$(basename $output_prefix)
	pre_string=${pre_string%_}
	pre_string=${pre_string}"_"
fi
#if the output dir does not exsts yet, lets make it
if [ ! -d $dirpath ]
then
   mkdir -p $dirpath
fi
output_call=${dirpath}${pre_string}
output_call=$(readlink -f "${output_call}")

####################################################################

# report the parameters to the USER
reportMappingParameters

#if we get this far, lets output to a notes file
OUT=${output_call}pAnts.log
touch $OUT
#and write some stuff to the notes file
echo "USER: $USER" >> $OUT
time=$(date)
echo "DATE: ${time}" >> $OUT
echo >> $OUT
reportMappingParameters >> $OUT
echo >> $OUT

time_start=$(date +%s)

#the actual antRegistration call
#ill let this call do more of the checking of params...

#TODO parse out base on required an non-required metrics

cmd="$antsRegistration -d 3 \
		--output [${output_call},${output_call}deformed.nii.gz,${output_call}fixedInvDeformed.nii.gz] \
		--write-composite-transform ${write_composite_transform} \
		--interpolation 'Linear' \
		--restrict-deformation ${constrain_z_direction} \
		--metric ${metric_call} \
		--transform ${transform_call} \
		--convergence ${convergence_call} \
		--smoothing-sigmas ${smooth_sigmas}vox \
		--shrink-factors ${shrink_factors} \
		"
if [ ${use_histogram_matching} == "1" ]; then
	cmd="${cmd} -u "
fi
if [ ${winsorize_intensity} != "0" ]; then
	cmd="${cmd} -w ${winsorize_intensity}"
fi
echo $cmd
echo $cmd >> $OUT
eval $cmd 

#check if output exists
if [[ ! -f "${output_call}"1Warp.nii.gz ]] && [[ ! -f "${output_call}"0Warp.nii.gz ]]
then
	echo -e "\n\nSomething wrong happened and the warp file was not computed by \
antsRegistration.\nSkipping, exiting.\n\n"
	exit 1
fi

#a quick compute of dice stats, taken from antsIntrodcution code
#https://github.com/stnava/ANTs/blob/master/Scripts/antsIntroduction.sh
cmd="${ANTSPATH}/ThresholdImage 3 ${fixed_image} ${output_call}fixthresh.nii.gz Otsu 4"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

cmd="${ANTSPATH}/ThresholdImage 3 ${moving_image} ${output_call}movthresh.nii.gz Otsu 4"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

cmd="${ANTSPATH}/antsApplyTransforms -d 3 --input ${output_call}movthresh.nii.gz --output ${output_call}defthresh.nii.gz --reference-image ${fixed_image} --interpolation NearestNeighbor --transform ${output_call}?Warp.nii.gz"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

cmd="${ANTSPATH}/ImageMath 3 ${output_call}dicestats DiceAndMinDistSum ${output_call}fixthresh.nii.gz ${output_call}movthresh.nii.gz" 
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

#Usage: CreateJacobianDeterminantImage imageDimension deformationField outputImage [doLogJacobian=0] [useGeometric=0]
cmd="CreateJacobianDeterminantImage 3 \
	${output_call}?Warp.nii.gz ${output_call}log_jacobian.nii.gz 1 0 \
	"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

cmd="CreateJacobianDeterminantImage 3 \
	${output_call}?Warp.nii.gz ${output_call}log_geo_jacobian.nii.gz 1 1 \
	"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

#some cleanup
cmd="rm ${output_call}dicestatsdice.nii.gz"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command
cmd="rm ${output_call}dicestatsmds.nii.gz"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command
cmd="rm ${output_call}dicestats"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

time_end=`date +%s`
time_elapsed=$((time_end - time_start))

echo -e "\n${script_name} took ${time_elapsed} seconds to complete. Check ${dirpath} for the results\n" >> $OUT
echo -e "\n${script_name} took ${time_elapsed} seconds to complete. Check ${dirpath} for the results\n" 


cmd="cp ${SGE_STDOUT_PATH} ${output_call}output.out"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

cmd="cp ${SGE_STDERR_PATH} ${output_call}error.out"
echo $cmd #state the command
echo $cmd >> $OUT
eval $cmd #execute the command

#do some stuff to print out some nice logs for metrics 

outLog=${SGE_STDOUT_PATH}
#outLog="${outLog#*:}"'.out'

lineStart=$(grep -ni "Running.* ${transform_for_log} registration" ${outLog})
lineStart="${lineStart%%:*}"
lineEnd=$(grep -n 'Total elapsed time:' ${outLog})
lineEnd="${lineEnd%%:*}"

sedCall="${lineStart},${lineEnd}p;${lineEnd}d"
sed -n "${sedCall}" "${outLog}"  > ${output_call}transformInfo.log
awk 'BEGIN { FS = "," } ; { if ($2 ~ /[0-9]/ && $1 ~ /DIAGNOSTIC/) 
	print $2","$3","$4 ;}' ${output_call}transformInfo.log > ${output_call}justMetric.log 

##############################
##############################
##############################

#if there is an image to apply to, apply Warp to that image
if [[ ${image_to_apply_to^^} == "NONE" ]] ; then
	echo ""
elif [[ -n ${image_to_apply_to} ]] ; then
	#get the image dimension of the image to apply to
	#because it could be 4D dwi...
	image_apply_dim=$(${ANTSPATH}/PrintHeader ${image_to_apply_to} | awk '/\ dim\[0\]/ {print $3}')

	apply_basename=$(basename ${image_to_apply_to})
	apply_basename=${apply_basename%%.*}

	if [ ${image_apply_dim} -eq 3 ] ; then 

		echo -e "\nApplying warp to the image: ${image_to_apply_to}"

		cmd="${ANTSPATH}/antsApplyTransforms -d 3 \
				--input ${image_to_apply_to} \
				--output ${output_call}${apply_basename}_warpApply.nii.gz \
				--reference-image ${fixed_image} \
				--interpolation Linear \
				--transform ${output_call}?Warp.nii.gz"
		echo $cmd #state the command
		echo $cmd >> $OUT
		eval $cmd #execute the command

	elif [ ${image_apply_dim} -eq 4 ] ; then 

		echo -e "\nApplying warp to the image: ${image_to_apply_to}"

		cmd="${ANTSPATH}/antsApplyTransforms -d 3 \
				-e 3 \
				--input ${image_to_apply_to} \
				--output ${output_call}${apply_basename}_warpApply.nii.gz \
				--reference-image ${fixed_image} \
				--interpolation Linear \
				--transform ${output_call}?Warp.nii.gz"
		echo $cmd #state the command
		echo $cmd >> $OUT
		eval $cmd #execute the command

	else 
		echo -e "\nHad trouble reading the dimension of image to apply do.\n \
Dont worry, the registration (besides this apply transform, should be complete." 
		exit 1
	fi
fi











