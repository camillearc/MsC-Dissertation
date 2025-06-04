#!/bin/bash
#most recent version
# LAST TESTED: unclear

perps=("sub-1" "sub-2" "sub-3" "sub-4" "sub-5" "sub-6" "sub-7" "sub-8" "sub-9" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19" "sub-20" "sub-22" "sub-23" "sub-24" "sub-25" "sub-26" "sub-27" "sub-28" "sub-29" "sub-30" "sub-31" "sub-32" "sub-33" "sub-34" "sub-35" "sub-36" "sub-37" "sub-38" "sub-39" "sub-40" "sub-41" "sub-42" "sub-43" "sub-44" "sub-45" "sub-46" "sub-47" "sub-48" "sub-49" "sub-50" "sub-51" "sub-52" "sub-53" "sub-54" "sub-55" "sub-56" "sub-57" "sub-58" "sub-59" "sub-60" "sub-61" "sub-62" "sub-63" "sub-64" "sub-65" "sub-66" "sub-67" "sub-68" "sub-69" "sub-70" "sub-71" "sub-72" "sub-73" "sub-74" "sub-75" "sub-76" "sub-77" "sub-78" "sub-79" "sub-80" "sub-81" "sub-82" "sub-83" "sub-84" "sub-85" "sub-86")

movies=("500daysofsummer" "12yearsaslave" "backtothefuture" "citizenfour" "littlemisssunshine" "pulpfiction" "theshawshankredemption" "split" "theprestige" "theusualsuspects")

# Set Directories
# Annotations
annotation_dir="/data/carcher/nndb/annotations" #these are the 1D files- timing files of the 'stimuli' ***have to change files in here 

# Output
output_dir="/data/carcher/nndb/deconoutput" 

for perp in "${perps[@]}"; do 
    folder_name="${perp}"
    file_path="/Users/camillearcher/3dDeconvolveTesting/$folder_name" 
    mask_file="${perp}_t1w_mask_epi_anat.nii.gz" 
    for movie in "${movies[@]}"; do
        func_file="${perp}_task-${movie}_bold_blur_censor_ica.nii.gz" #using blur and censor for the deconvolution step
        de_prefix="word_categories" 
        de_suffix="convolved"

                #Debugging/checking
                cd "$output_dir"
                echo "####################################################################################################"
                echo "# $perp: Doing 3dDeconvolve for $movie"
                echo "####################################################################################################"

				echo "Output 1D file: ${perp}_${de_prefix}_${de_suffix}.1D"
                echo "Output Coefficients bucket file: ${perp}_${de_prefix}_coefficients_${de_suffix}.nii.gz"
                echo "Output Stats bucket file: ${perp}_${de_prefix}_stats_${de_suffix}.nii.gz"
                
                echo "Mask File Path: $file_path/anat/$mask_file"
                echo "Functional File Path: $file_path/func/$func_file"


                3dDeconvolve \
                -mask "$file_path/anat/$mask_file" \
                -input "$file_path/func/$func_file" \
                -polort -1 \
                -num_stimts 33 \
                -global_times \
                -stim_times 1 "$annotation_dir/${movie}_cognitive.1D"     'TENT(0, 15, 16)' -stim_label 1 cognitive \
                -stim_times 2 "$annotation_dir/${movie}_cognitive_matches.1D" 'TENT(0, 15, 16)' -stim_label 2 cog_matches \
				-stim_times 3 "$annotation_dir/${movie}_concrete.1D" 'TENT(0, 15, 16)' -stim_label 3 concrete \
				-stim_times 4 "$annotation_dir/${movie}_concrete_matches.1D" 'TENT(0, 15, 16)' -stim_label 4 con_matches \
				-stim_times 5 "$annotation_dir/${movie}_drive.1D" 'TENT(0, 15, 16)' -stim_label 5 drive \
				-stim_times 6 "$annotation_dir/${movie}_drive_matches.1D" 'TENT(0, 15, 16)' -stim_label 6 drive_matches \
				-stim_times 7 "$annotation_dir/${movie}_first.1D" 'TENT(0, 15, 16)' -stim_label 7 first \
				-stim_times 8 "$annotation_dir/${movie}_first_matches.1D" 'TENT(0, 15, 16)' -stim_label 8 first_matches \
				-stim_times 9 "$annotation_dir/${movie}_future.1D" 'TENT(0, 15, 16)' -stim_label 9 future \
				-stim_times 10 "$annotation_dir/${movie}_future_matches.1D" 'TENT(0, 15, 16)' -stim_label 10 future_matches \
				-stim_times 11 "$annotation_dir/${movie}_lifestyle.1D" 'TENT(0, 15, 16)' -stim_label 11 lifestyle \
				-stim_times 12 "$annotation_dir/${movie}_lifestyle_matches.1D" 'TENT(0, 15, 16)' -stim_label 12 life_matches \
				-stim_times 13 "$annotation_dir/${movie}_negation.1D" 'TENT(0, 15, 16)' -stim_label 13 negation \
				-stim_times 14 "$annotation_dir/${movie}_negation_matches.1D" 'TENT(0, 15, 16)' -stim_label 14 nega_matches \
				-stim_times 15 "$annotation_dir/${movie}_negative.1D" 'TENT(0, 15, 16)' -stim_label 15 negative \
				-stim_times 16 "$annotation_dir/${movie}_negative_matches.1D" 'TENT(0, 15, 16)' -stim_label 16 neg_matches \
				-stim_times 17 "$annotation_dir/${movie}_past.1D" 'TENT(0, 15, 16)' -stim_label 17 past \
				-stim_times 18 "$annotation_dir/${movie}_past_matches.1D" 'TENT(0, 15, 16)' -stim_label 18 past_matches \
				-stim_times 19 "$annotation_dir/${movie}_perception.1D" 'TENT(0, 15, 16)' -stim_label 19 perception \
				-stim_times 20 "$annotation_dir/${movie}_perception_matches.1D" 'TENT(0, 15, 16)' -stim_label 20 per_matches \
				-stim_times 21 "$annotation_dir/${movie}_physical.1D" 'TENT(0, 15, 16)' -stim_label 21 physical \
				-stim_times 22 "$annotation_dir/${movie}_physical_matches.1D" 'TENT(0, 15, 16)' -stim_label 22 phy_matches \
				-stim_times 23 "$annotation_dir/${movie}_present.1D" 'TENT(0, 15, 16)' -stim_label 23 present \
				-stim_times 24 "$annotation_dir/${movie}_present_matches.1D" 'TENT(0, 15, 16)' -stim_label 24 pres_matches \
				-stim_times 25 "$annotation_dir/${movie}_positive.1D" 'TENT(0, 15, 16)' -stim_label 25 positive \
				-stim_times 26 "$annotation_dir/${movie}_positive_matches.1D" 'TENT(0, 15, 16)' -stim_label 26 pos_matches \
				-stim_times 27 "$annotation_dir/${movie}_second.1D" 'TENT(0, 15, 16)' -stim_label 27 second \
				-stim_times 28 "$annotation_dir/${movie}_second_matches.1D" 'TENT(0, 15, 16)' -stim_label 28 sec_matches \
				-stim_times 29 "$annotation_dir/${movie}_social.1D" 'TENT(0, 15, 16)' -stim_label 29 social \
				-stim_times 30 "$annotation_dir/${movie}_social_matches.1D" 'TENT(0, 15, 16)' -stim_label 30 soc_matches \
				-stim_times 31 "$annotation_dir/${movie}_third.1D" 'TENT(0, 15, 16)' -stim_label 31 third \
				-stim_times 32 "$annotation_dir/${movie}_third_matches.1D" 'TENT(0, 15, 16)' -stim_label 32 third_matches \
                -stim_times 33 "$annotation_dir/${movie}_other_words.1D"   'TENT(0, 15, 16)' -stim_label 33 others \
                            -num_glt 40 \
                    		-gltsym 'SYM: +cognitive[0] -cog_matches[0]'   -glt_label 1 cog_vs_matches \
                    		-gltsym 'SYM: +cognitive[0] -others[0]'     -glt_label 2 cog_vs_others \
				-gltsym 'SYM: +concrete[0] -con_matches[0]'   -glt_label 3 con_vs_matches \
				-gltsym 'SYM: +concrete[0] -others[0]'   -glt_label 4 con_vs_others \
				-gltsym 'SYM: +drive[0] -drive_matches[0]'   -glt_label 5 drive_vs_matches \
				-gltsym 'SYM: +drive[0] -others[0]'   -glt_label 6 drive_vs_others \
				-gltsym 'SYM: +first[0] -first_matches[0]'   -glt_label 7 first_vs_matches \
				-gltsym 'SYM: +first[0] -others[0]'   -glt_label 8 first_vs_others \
				-gltsym 'SYM: +future[0] -future_matches[0]'   -glt_label 9 future_vs_matches \
				-gltsym 'SYM: +future[0] -others[0]'   -glt_label 10 future_vs_others \
				-gltsym 'SYM: +lifestyle[0] -life_matches[0]'   -glt_label 11 life_vs_matches \
				-gltsym 'SYM: +lifestyle[0] -others[0]'   -glt_label 12 life_vs_matches \
				-gltsym 'SYM: +negation[0] -nega_matches[0]'   -glt_label 13 nega_vs_matches \
				-gltsym 'SYM: +negation[0] -others[0]'   -glt_label 14 nega_vs_others \
				-gltsym 'SYM: +negative[0] -neg_matches[0]'   -glt_label 15 neg_vs_matches \
				-gltsym 'SYM: +negative[0] others[0]'   -glt_label 16 neg_vs_others \
				-gltsym 'SYM: +past[0] -past_matches[0]'   -glt_label 17 past_vs_matches \
				-gltsym 'SYM: +past[0] -others[0]'   -glt_label 18 past_vs_others \
				-gltsym 'SYM: +perception[0] -per_matches[0]'   -glt_label 19 per_vs_matches \
				-gltsym 'SYM: +perception[0] -others[0]'   -glt_label 20 per_vs_others \
				-gltsym 'SYM: +physical[0] -phy_matches[0]'   -glt_label 21 phy_vs_matches \
				-gltsym 'SYM: +physical[0] -others[0]'   -glt_label 22 phy_vs_others \
				-gltsym 'SYM: +positive[0] -pos_matches[0]'   -glt_label 23 pos_vs_matches \
				-gltsym 'SYM: +positive[0] -others[0]'   -glt_label 24 pos_vs_others \
				-gltsym 'SYM: +present[0] -pres_matches[0]'   -glt_label 25 pres_vs_matches \
				-gltsym 'SYM: +present[0] -others[0]'   -glt_label 26 pres_vs_others \
				-gltsym 'SYM: +second[0] -sec_matches[0]'   -glt_label 27 sec_vs_matches \
				-gltsym 'SYM: +second[0] -others[0]'   -glt_label 28 sec_vs_others \
				-gltsym 'SYM: +social[0] -soc_matches[0]'   -glt_label 29 soc_vs_matches \
				-gltsym 'SYM: +social[0] -others[0]'   -glt_label 30 soc_vs_others \
				-gltsym 'SYM: +third[0] -third_matches[0]'   -glt_label 31 third_vs_matches \
                    		-gltsym 'SYM: +third[0] -others[0]' -glt_label 32 third_vs_others \
				-gltsym 'SYM: +cognitive[0] -concrete[0]'   -glt_label 33 cog_vs_con \
				-gltsym 'SYM: +first[0] -second[0]'   -glt_label 34 first_vs_second \
				-gltsym 'SYM: +first[0] -third[0]'   -glt_label 35 first_vs_third \
				-gltsym 'SYM: +second[0] -third[0]'   -glt_label 36 second_vs_third \
				-gltsym 'SYM: +future[0] -past[0]'   -glt_label 37 future_vs_past \
				-gltsym 'SYM: +future[0] -present[0]'   -glt_label 38 future_vs_present \
				-gltsym 'SYM: +present[0] -past[0]'   -glt_label 39 present_vs_past \
				-gltsym 'SYM: +negative[0] -positive[0]'   -glt_label 40 neg_vs_pos \
                    		-fout -tout -full_first \
                    		-xsave \
                    		-x1D     "$perp"_"$de_prefix"_"$de_suffix".1D \
                    		-cbucket "$perp"_"$de_prefix"_coefficients_"$de_suffix".nii.gz \
                    		-bucket  "$perp"_"$de_prefix"_stats_"$de_suffix".nii.gz 
    done
done
