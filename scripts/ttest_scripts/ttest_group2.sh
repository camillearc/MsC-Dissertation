#!/bin/bash

# ttest Group 2: physical, present, past categories and their matches

# Start time
start_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "####################################################################################################"
echo "Starting ttest_group2.sh at $start_time"

# Subject list
perps=("sub-1" "sub-2" "sub-3" "sub-4" "sub-5" "sub-6" "sub-7" "sub-8" "sub-9" "sub-10" "sub-11" "sub-12" "sub-13" "sub-14" "sub-15" "sub-16" "sub-17" "sub-18" "sub-19" "sub-20" "sub-21" "sub-22" "sub-23" "sub-24" "sub-25" "sub-26" "sub-27" "sub-28" "sub-29" "sub-30" "sub-31" "sub-32" "sub-33" "sub-34" "sub-35" "sub-36" "sub-37" "sub-38" "sub-39" "sub-40" "sub-41" "sub-42" "sub-43" "sub-44" "sub-45" "sub-46" "sub-47" "sub-48" "sub-49" "sub-50" "sub-51" "sub-52" "sub-53" "sub-54" "sub-55" "sub-56" "sub-57" "sub-58" "sub-59" "sub-60" "sub-61" "sub-62" "sub-63" "sub-64" "sub-65" "sub-66" "sub-67" "sub-68" "sub-69" "sub-70" "sub-71" "sub-72" "sub-73" "sub-74" "sub-75" "sub-76" "sub-77" "sub-78" "sub-79" "sub-80" "sub-81" "sub-82" "sub-83" "sub-84" "sub-85" "sub-86")


# Set Directories
base_data_dir="/data/carcher/deconoutput"
mask_dir="/data/carcher/misc" 
output_dir="/data/carcher/ttest_analysis_v2/ttest_output" 
cov_file="/data/carcher/ttest_analysis/covariates.txt"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"
cd "$output_dir"
echo "Now running in directory: $(pwd)"

# Function to get base condition for vs_others comparisons
get_base_condition() {
    local comparison=$1
    if [[ $comparison == *_vs_others ]]; then
        echo "${comparison%_vs_others}"
    else
        echo "$comparison"
    fi
}

#this should be fine, but checking for all input files first
for perp in "${perps[@]}"; do
    input_file="${base_data_dir}/${perp}_word_categories_stats_convolved.nii.gz"
    if [ ! -f "$input_file" ]; then
        echo "ERROR: Missing input file for $perp: $input_file"
        exit 1
    fi
done

# Main processing loop
for perp in "${perps[@]}"; do
    echo "Processing subject: $perp"
    
    # Mask file 
    mask_file="${mask_dir}/TT_mask.nii.gz"
    
    # Check if the mask file exists
    if [ ! -f "$mask_file" ]; then
        echo "WARNING: Mask file not found: $mask_file"
        continue
    fi

    # Define word groups and their sub-bricks
    declare -A word_group_subbricks=(
        [physical]="199 201 203 205 207 209 211 213 215 217 219 221 223 225 227 229"
        [present]="265 267 269 271 273 275 277 279 281 283 285 287 289 291 293 295"
        [past]="331 333 335 337 339 341 343 345 347 349 351 353 355 357 359 361"
    )

    declare -A match_subbricks=(
        [physical_match]="232 234 236 238 240 242 244 246 248 250 252 254 256 258 260 262"
        [present_match]="298 300 302 304 306 308 310 312 314 316 318 320 322 324 326 328"
        [past_match]="364 366 368 370 372 374 376 378 380 382 384 386 388 390 392 394"
        [others]="529 531 533 535 537 539 541 543 545 547 549 551 553 555 557 559"
    )

    # Define group relationships
    declare -A comparisons=(
        [physical]=physical_match
        [present]=present_match
        [past]=past_match
        [physical_vs_others]=others
        [present_vs_others]=others
        [past_vs_others]=others
    )

    # Process each comparison
    for comparison in "${!comparisons[@]}"; do
        echo "Processing category: ${comparison} vs ${comparisons[$comparison]}"
        
        # Get indices for this comparison
        if [[ $comparison == *_vs_others ]]; then
            base_condition=$(get_base_condition $comparison)
            word_group_indices=(${word_group_subbricks[$base_condition]})
            match_indices=(${match_subbricks[others]})
        else
            word_group_indices=(${word_group_subbricks[$comparison]})
            match_indices=(${match_subbricks[${comparisons[$comparison]}]})
        fi

        # Process each time point
        for ((i=0; i<${#word_group_indices[@]}; i++)); do
            word_group_index=${word_group_indices[$i]}
            neutral_match_index=${match_indices[$i]}
            
            echo "Processing sub-brick pair: ${comparison}_${i} (${word_group_index}) vs ${comparisons[$comparison]}_${i} (${neutral_match_index})"

            # Create temp directory for this comparison
            temp_dir="/data/carcher/ttest_analysis/etac_temp/${comparison}_time${i}_vs_${comparisons[$comparison]}_time${i}"
            mkdir -p "$temp_dir"
            
            # Run 3dttest++
            3dttest++ \
                -prefix "${comparison}_time${i}_vs_${comparisons[$comparison]}_time${i}" \
                -prefix_clustsim "${comparison}_time${i}_vs_${comparisons[$comparison]}_time${i}" \
                -mask "$mask_file" \
                -ETAC \
                -ETAC_opt "sid=2:pthr=0.05,0.02,0.01,0.005,0.002,0.001:fpr=5:name=Thresholding" \
                -tempdir "$temp_dir" \
                -paired \
                -covariates "$cov_file" \
                -setA "${comparison}" \
                $(for perp in "${perps[@]}"; do
                    echo "${perp} ${base_data_dir}/${perp}_word_categories_stats_convolved.nii.gz[${word_group_index}]"
                done) \
                -setB "${comparisons[$comparison]}" \
                $(for perp in "${perps[@]}"; do
                    echo "${perp} ${base_data_dir}/${perp}_word_categories_stats_convolved.nii.gz[${neutral_match_index}]"
                done)
            
            # Clean up
            rm -f minmax.1D 2>/dev/null
            
            echo "Completed t-test for ${comparison}_time${i} vs ${comparisons[$comparison]}_time${i}"
        done
    done
done

echo "Script completed at $(date)"
