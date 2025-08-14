#!/bin/bash

# Generic script to process all contrast files with 3dcalc
# This script will automatically detect file patterns and create positive/negative outputs
# Works with any naming pattern (e.g., past_vs_present, physical_vs_physical_match, etc.)
#creates the individual contrast files
#activation for the word category is always positive, while negative activation means the matches
#category was more active

# USER-CONFIGURABLE TIME WINDOWS
# Modify these ranges as needed for your analysis
EARLY_START=0
EARLY_END=3
MIDDLE_START=4
MIDDLE_END=7
LATE_START=8
LATE_END=15

# Base directory containing ttest_output
BASE_DIR="/data/carcher/ttest_analysis_v2/category_vs_category"

# Function to process a directory
process_directory() {
    local dir_path="$1"
    cd "$dir_path" || { echo "Failed to enter directory: $dir_path"; return 1; }
    
    echo "\n=== Processing directory: $dir_path ==="
    echo "Time windows: Early ($EARLY_START-$EARLY_END), Middle ($MIDDLE_START-$MIDDLE_END), Late ($LATE_START-$LATE_END)"
    
    # Create output directories if they don't exist
    mkdir -p "$dir_path/merged_outputs/individuals"
    mkdir -p "$dir_path/merged_outputs/merged"
    
    # Clean up old output files
    echo "Cleaning up old output files..."
    rm -f "$dir_path/merged_outputs/individuals/"*_directionality.nii.gz
    rm -f "$dir_path/merged_outputs/merged/"*_merged.nii.gz
    rm -f "$dir_path/merged_outputs/individuals/temp_"*.nii.gz
    echo "✓ Old files removed"
    echo ""
    
    # Arrays to store output files for merging
    local past_files=()
    local present_files=()
    local all_files=()
    
    # Find all BRIK files in current directory
    echo "Detecting file patterns in $(pwd)..."
    for brik_file in *+tlrc.BRIK; do
    if [[ -f "$brik_file" ]]; then
        # Extract base name (remove +tlrc.BRIK)
        base_name="${brik_file%+tlrc.BRIK}"
        mask_file="${base_name}.Thresholding.ETACmask.global.2sid.05perc.nii.gz"
        
        echo "Found: $base_name"
        
        # Check if corresponding mask file exists
        if [[ -f "$mask_file" ]]; then
            echo "  Mask file found: $mask_file"
            
            # Extract contrast terms from filename (e.g., "first_time7_vs_cognitive_time7" -> "first" and "cognitive")
            if [[ $base_name =~ ^([^_]+)_time([0-9]+)_vs_([^_]+)_time([0-9]+)$ ]]; then
                # For pattern: first_time7_vs_cognitive_time7
                term1="${BASH_REMATCH[1]}"
                timepoint1="${BASH_REMATCH[2]}"
                term2="${BASH_REMATCH[3]}"
                timepoint2="${BASH_REMATCH[4]}"
                
                # Verify time points match (they should in a valid comparison)
                if [[ "$timepoint1" != "$timepoint2" ]]; then
                    echo "  ⚠️ Warning: Time points don't match in filename: $base_name"
                    continue
                fi
                
                timepoint="$timepoint1"
                echo "  Detected terms: $term1 vs $term2 at time $timepoint"
                
                # Create output filenames
                output_prefix="${term1}_vs_${term2}_time${timepoint}"
                positive_output="${output_prefix}.${term1}_positive_directionality.nii.gz"
                negative_output="${output_prefix}.${term2}_negative_directionality.nii.gz"
            else
                # Try the old pattern (e.g., "past_vs_present_time7")
                if [[ "$base_name" =~ ^(.+)_vs_(.+)_time([0-9]+)$ ]]; then
                    term1="${BASH_REMATCH[1]}"
                    term2="${BASH_REMATCH[2]}"
                    timepoint="${BASH_REMATCH[3]}"
                    
                    echo "  Detected terms (old format): $term1 vs $term2 at time $timepoint"
                    
                    # Create output filenames
                    output_prefix="${term1}_vs_${term2}_time${timepoint}"
                    positive_output="${output_prefix}.${term1}_positive_directionality.nii.gz"
                    negative_output="${output_prefix}.${term2}_negative_directionality.nii.gz"
                else
                    echo "  ⚠️ Warning: Could not parse filename pattern: $base_name"
                    continue
                fi
            fi
            
            # Define output files using extracted condition names
            temp_nii="merged_outputs/individuals/temp_${base_name}.nii.gz"
            positive_output="merged_outputs/individuals/${base_name}.${term1}_positive_directionality.nii.gz"
            negative_output="merged_outputs/individuals/${base_name}.${term2}_negative_directionality.nii.gz"
            
            echo "  Processing $base_name..."
            echo "    BRIK: $brik_file"
            echo "    Mask: $mask_file"
            echo "    Positive (${term1}): $positive_output"
            echo "    Negative (${term2}): $negative_output"
            
            # Convert BRIK to NIfTI format
            echo "    Converting BRIK to NIfTI..."
            3dAFNItoNIFTI -prefix "$temp_nii" "$brik_file"
            
            if [[ $? -eq 0 && -f "$temp_nii" ]]; then
                echo "    Successfully converted to NIfTI"
                
                # Create positive output (term1 activity)
                echo "    Running 3dcalc for positive (${term1}) activity..."
                3dcalc \
                    -a "$temp_nii" \
                    -b "$mask_file" \
                    -expr 'a*step(b)*step(a)' \
                    -prefix "$positive_output"
                
                if [[ $? -eq 0 ]]; then
                    echo "    Successfully created ${condition1_clean} (positive) output"
                    past_files+=("$positive_output")
                    all_files+=("$positive_output")
                else
                    echo "    Error creating ${condition1_clean} (positive) output"
                fi
                
                # Create negative output (condition2 activity)
                echo "    Running 3dcalc for negative (${condition2_clean}) activity..."
                3dcalc \
                    -a "$temp_nii" \
                    -b "$mask_file" \
                    -expr 'a*step(b)*step(-a)' \
                    -prefix "$negative_output"
                
                if [[ $? -eq 0 ]]; then
                    echo "    Successfully created ${condition2_clean} (negative) output"
                    present_files+=("$negative_output")
                    all_files+=("$negative_output")
                else
                    echo "    Error creating ${condition2_clean} (negative) output"
                fi
                
                # Clean up temporary file
                rm -f "$temp_nii"
                
            else
                echo "    Error converting BRIK to NIfTI"
            fi
            
        else
            echo "  Warning: No mask file found for $base_name"
        fi
        
        echo ""
    fi
done

    # Only proceed with merging if we found files
    if [[ ${#all_files[@]} -eq 0 ]]; then
        echo "No valid files found in $dir_path"
        cd - > /dev/null || return 1
        return 1
    fi

    # Now combine results using 3dmerge
    echo "Starting 3dmerge to combine results..."
    echo ""
    
    # 1. Update file paths in the arrays to point to the individuals directory
    past_files=("${past_files[@]/merged_outputs\//merged_outputs/individuals/}")
    present_files=("${present_files[@]/merged_outputs\//merged_outputs/individuals/}")
    all_files=("${all_files[@]/merged_outputs\//merged_outputs/individuals/}")
    
    # 2. Merge POSITIVE files
    if [[ ${#past_files[@]} -gt 0 ]]; then
        echo "Merging POSITIVE files..."
        3dmerge -dxyz=1 -1clust 1 20 -prefix "$dir_path/merged_outputs/merged/all_positive_merged.nii.gz" "${past_files[@]}" || echo "Error merging positive files"
    fi
    
    # 3. Merge NEGATIVE files
    if [[ ${#present_files[@]} -gt 0 ]]; then
        echo "Merging NEGATIVE files..."
        3dmerge -dxyz=1 -1clust 1 20 -prefix "$dir_path/merged_outputs/merged/all_negative_merged.nii.gz" "${present_files[@]}" || echo "Error merging negative files"
    fi
    
    # 4. Merge ALL files
    if [[ ${#all_files[@]} -gt 0 ]]; then
        echo "Merging ALL files..."
        3dmerge -dxyz=1 -1clust 1 20 -prefix "$dir_path/merged_outputs/merged/all_merged.nii.gz" "${all_files[@]}" || echo "Error merging all files"
    fi
    
    # 4. Merge by time windows
    echo "\nMerging by time windows..."
    

    # Function to merge files within a time window

    #these are the maps i want to actually present within text - three per word category
#i need these to display the colors differently - they currently do not

    merge_window() {
        local window_name="$1"
        local start_time="$2"
        local end_time="$3"
        
        echo "Processing $window_name window (time $start_time to $end_time)..."
        
        # Find files in this time window
        local window_files=()
        local positive_files=()
        local negative_files=()
        
        for ((t=start_time; t<=end_time; t++)); do
            for f in "$dir_path/merged_outputs/individuals/"*"_time${t}."*.nii.gz; do
                if [[ -f "$f" ]]; then
                    window_files+=("$f")
                    
                    # Check if it's a positive or negative file
                    if [[ "$f" == *"_positive_"* ]]; then
                        positive_files+=("$f")
                    elif [[ "$f" == *"_negative_"* ]]; then
                        negative_files+=("$f")
                    fi
                fi
            done
        done
        
        # Merge positive files for this window
        if [[ ${#positive_files[@]} -gt 0 ]]; then
            3dmerge -dxyz=1 -1clust 1 20 -prefix "$dir_path/merged_outputs/merged/positive_${window_name}_merged.nii.gz" "${positive_files[@]}" || \
                echo "Error merging positive files for $window_name window"
        fi
        
        # Merge negative files for this window
        if [[ ${#negative_files[@]} -gt 0 ]]; then
            3dmerge -dxyz=1 -1clust 1 20 -prefix "$dir_path/merged_outputs/merged/negative_${window_name}_merged.nii.gz" "${negative_files[@]}" || \
                echo "Error merging negative files for $window_name window"
        fi
        
        # Merge all files for this window
        if [[ ${#window_files[@]} -gt 0 ]]; then
            3dmerge -dxyz=1 -1clust 1 20 -prefix "$dir_path/merged_outputs/merged/combined_${window_name}_merged.nii.gz" "${window_files[@]}" || \
                echo "Error merging all files for $window_name window"
        fi
    }
    
    # Change to merged_outputs directory for windowed merges
    cd "$dir_path/merged_outputs" || { echo "Failed to enter merged_outputs directory"; return 1; }
    


    #these are the most minimial merged files

    # Merge positive files by time window
    if [[ ${#past_files[@]} -gt 0 ]]; then
        echo "Merging POSITIVE files by time window..."
        merge_by_window "early" "$EARLY_START" "$EARLY_END" "positive" "positive_early"
        merge_by_window "middle" "$MIDDLE_START" "$MIDDLE_END" "positive" "positive_middle"
        merge_by_window "late" "$LATE_START" "$LATE_END" "positive" "positive_late"
    fi
    
    # Merge negative files by time window
    if [[ ${#present_files[@]} -gt 0 ]]; then
        echo "Merging NEGATIVE files by time window..."
        merge_by_window "early" "$EARLY_START" "$EARLY_END" "negative" "negative_early"
        merge_by_window "middle" "$MIDDLE_START" "$MIDDLE_END" "negative" "negative_middle"
        merge_by_window "late" "$LATE_START" "$LATE_END" "negative" "negative_late"
    fi
    
    # Merge all files by time window
    if [[ ${#all_files[@]} -gt 0 ]]; then
        echo "Merging ALL files by time window..."
        merge_by_window "early" "$EARLY_START" "$EARLY_END" "combined" "combined_early"
        merge_by_window "middle" "$MIDDLE_START" "$MIDDLE_END" "combined" "combined_middle"
        merge_by_window "late" "$LATE_START" "$LATE_END" "combined" "combined_late"
    fi
    
    echo "\nProcessing completed for $dir_path"
    echo "Outputs saved in: $dir_path/merged_outputs/"
    cd - > /dev/null || return 1
}

# Setup logging
LOG_FILE="$(dirname "$0")/processing_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Main execution starts here
echo "Starting generic 3dcalc processing..."
echo "Base directory: $BASE_DIR"
echo "Logging all output to: $LOG_FILE"

# Check if we're in a category_vs_category style directory (files directly in the base directory)
if ls "$BASE_DIR"/*+tlrc.BRIK 1> /dev/null 2>&1; then
    # Process files directly in the base directory
    echo "\nFound files directly in: $BASE_DIR"
    process_directory "$BASE_DIR"
else
    # Fall back to looking for matches subdirectories (original behavior)
    for category_dir in "$BASE_DIR"/*/; do
        # Skip if not a directory or if it's the merged_outputs directory
        [[ ! -d "$category_dir" || "$category_dir" == *"merged_outputs"* ]] && continue
        
        # Check if 'matches' directory exists in this category
        matches_dir="${category_dir}matches"
        if [[ -d "$matches_dir" ]]; then
            # Process the matches directory
            echo "\nFound matches directory: $matches_dir"
            process_directory "$matches_dir"
        else
            echo "\n⚠ No matches directory found in: $category_dir"
        fi
    done
fi

echo "\nAll processing complete!"
echo "Individual files were saved in their respective directories under merged_outputs/"

# Function to extract time point from filename
extract_timepoint() {
    local filename="$1"
    # Extract number after "time" (handles both time7 and time13 patterns)
    if [[ "$filename" =~ time([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "-1"  # Return -1 if no time point found
    fi
}

# Function to merge files by time window - so, early/middle/late 
merge_by_window() {
    local window_name="$1"
    local start_time="$2"
    local end_time="$3"
    local file_type="$4"  # "positive", "negative", or "combined"
    local output_prefix="$5"
    
    local window_files=()
    
    # Collect files in the time window based on file type 
    if [[ "$file_type" == "positive" ]]; then
        for file in "${past_files[@]}"; do
            timepoint=$(extract_timepoint "$file")
            if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                window_files+=("$file")
            fi
        done
    elif [[ "$file_type" == "negative" ]]; then
        for file in "${present_files[@]}"; do
            timepoint=$(extract_timepoint "$file")
            if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                window_files+=("$file")
            fi
        done
    elif [[ "$file_type" == "combined" ]]; then
        for file in "${all_files[@]}"; do
            timepoint=$(extract_timepoint "$file")
            if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                window_files+=("$file")
            fi
        done
    fi
    
    # Merge if files found
    if [[ ${#window_files[@]} -gt 0 ]]; then
        echo "  Merging $window_name window (time $start_time-$end_time): ${#window_files[@]} files"
        3dmerge -dxyz=1 -1clust 1 20 -prefix "${output_prefix}_${window_name}_merged.nii.gz" "${window_files[@]}"
        if [[ $? -eq 0 ]]; then
            echo "    ✓ Successfully merged $window_name window"
        else
            echo "    ✗ Error merging $window_name window"
        fi
    else
        echo "    ⚠ No files found for $window_name window (time $start_time-$end_time)"
    fi
}