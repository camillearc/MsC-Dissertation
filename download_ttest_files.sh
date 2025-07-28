#!/bin/bash

categories=("cognitive" "past" "first" "negative" "positive" "perception" "physical" "present")
categories_match=("cog_match" "past_match" "first_match" "negative_match" "positive_match" "perception_match" "physical_match" "present_match)
times=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)


# Download files with category matches
for i in "${!categories[@]}"; do
    category="${categories[$i]}"
    category_match="${categories_match[$i]}"
    
    for time in "${times[@]}"; do
        # Download with category-specific match
        remote_file="/data/carcher/ttest_analysis_v2/ttest_output/extra?/${category}_time${time}_vs_${category_match}_time${time}.Thresholding.ETACmask.global.2sid.05perc.nii.gz"
        local_dir="/Users/camillearcher/dissertation/ttest/${category}/"
        
        echo "Downloading ${remote_file} to ${local_dir}"
        scp "carcher@128.40.31.193:${remote_file}" "${local_dir}" || echo "Failed to download ${remote_file}"
        
        # Also download with 'others' as the matching category
        others_remote_file="/data/carcher/ttest_analysis_v2/ttest_output/past/${category}_vs_others_time${time}_vs_others_time${time}.Thresholding.ETACmask.global.2sid.05perc.nii.gz"
        echo "Downloading ${others_remote_file} to ${local_dir}"
        scp "carcher@128.40.31.193:${others_remote_file}" "${local_dir}" || echo "Failed to download ${others_remote_file}"
    done
done