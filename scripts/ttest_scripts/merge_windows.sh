#!/bin/bash

# Script to merge existing directionality files by time windows

#this should be set up correctly for real now - does NOT create individual files, go to
# jeremy_script.sh for that

# Time window definitions
EARLY_START=0
EARLY_END=3
MIDDLE_START=4
MIDDLE_END=7
LATE_START=8
LATE_END=15

# Function to extract timepoint from filename
extract_timepoint() {
    local filename=$(basename "$1")
    if [[ "$filename" =~ time([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "-1"
    fi
}

# Function to merge files by time window
merge_by_window() {
    local window_name="$1"
    local start_time="$2"
    local end_time="$3"
    local file_type="$4"  # "positive", "negative", or "combined"
    local output_prefix="$5"
    
    local window_files=()
    
    # Collect files in the time window based on file type
    if [[ "$file_type" == "positive" ]]; then
        pattern="*_positive_directionality.nii.gz"
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                timepoint=$(extract_timepoint "$file")
                if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                    window_files+=("$file")
                fi
            fi
        done
    elif [[ "$file_type" == "negative" ]]; then
        pattern="*_negative_directionality.nii.gz"
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                timepoint=$(extract_timepoint "$file")
                if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                    window_files+=("$file")
                fi
            fi
        done
    elif [[ "$file_type" == "combined" ]]; then
        # For combined, include both positive and negative files
        for file in *_positive_directionality.nii.gz; do
            if [[ -f "$file" ]]; then
                timepoint=$(extract_timepoint "$file")
                if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                    window_files+=("$file")
                fi
            fi
        done
        for file in *_negative_directionality.nii.gz; do
            if [[ -f "$file" ]]; then
                timepoint=$(extract_timepoint "$file")
                if [[ $timepoint -ge $start_time && $timepoint -le $end_time ]]; then
                    window_files+=("$file")
                fi
            fi
        done
    fi
    
    # Merge if files found
    if [[ ${#window_files[@]} -gt 0 ]]; then
        output_file="${output_prefix}.nii.gz"
        echo "  Merging $window_name window (time $start_time-$end_time): ${#window_files[@]} files"
        
        # Create merged file
        3dmerge -dxyz=1 -1clust 1 20 -prefix "$output_file" "${window_files[@]}"
        
        if [[ $? -eq 0 ]]; then
            echo "    ✓ Successfully created $output_file"
            
            # Move to merged directory if it exists and we're not already there
            if [[ -d "../merged" && "$(pwd)" != */merged && -f "$output_file" ]]; then
                mv "$output_file" "../merged/"
                echo "    ✓ Moved to merged/$(basename "$output_file")"
            fi
        else
            echo "    ✗ Error creating $output_file"
        fi
    else
        echo "    ⚠ No files found for $window_name window (time $start_time-$end_time)"
    fi
}

# Main script
BASE_DIR="/data/carcher/ttest_analysis_v2/ttest_output"
LOG_FILE="/data/carcher/window_merging_$(date +%Y%m%d_%H%M%S).log"

echo "Starting window merging process..." | tee "$LOG_FILE"
echo "Logging to: $LOG_FILE" | tee -a "$LOG_FILE"

# Find all matches directories
find "$BASE_DIR" -type d -name "matches" | while read -r matches_dir; do
    echo -e "\nProcessing directory: $matches_dir" | tee -a "$LOG_FILE"
    merged_dir="$matches_dir/merged_outputs"
    
    # Skip if no merged_outputs directory exists
    if [[ ! -d "$merged_dir" ]]; then
        echo "  ⚠ No merged_outputs directory found, skipping..." | tee -a "$LOG_FILE"
        continue
    fi
    
    cd "$merged_dir" || { echo "  ✗ Failed to enter $merged_dir" | tee -a "$LOG_FILE"; continue; }
    
    # Change to individuals directory if it exists
    if [[ -d "individuals" ]]; then
        cd "individuals" || { echo "  ✗ Failed to enter individuals/ directory" | tee -a "$LOG_FILE"; continue; }
        echo "  Processing files in $(pwd)" | tee -a "$LOG_FILE"
    fi
    
    # Function to create merged file for all timepoints of a specific type
    merge_all_timepoints() {
        local file_type=$1  # "positive" or "negative"
        local output_prefix=$2
        local search_pattern="*_${file_type}_directionality.nii.gz"
        local all_files=()
        
        # Find all matching files in current directory and individuals/ subdirectory
        for file in $search_pattern individuals/$search_pattern; do
            if [[ -f "$file" ]]; then
                all_files+=("$file")
            fi
        done
        
        if [[ ${#all_files[@]} -gt 0 ]]; then
            echo "  Merging ALL ${file_type} files (${#all_files[@]} files)..." | tee -a "$LOG_FILE"
            3dmerge -dxyz=1 -1clust 1 20 -prefix "${output_prefix}_all_${file_type}_merged.nii.gz" "${all_files[@]}"
            if [[ $? -eq 0 ]]; then
                echo "    ✓ Successfully created ${output_prefix}_all_${file_type}_merged.nii.gz" | tee -a "$LOG_FILE"
                # Move to merged directory if it exists
                if [[ -d "../merged" && -f "${output_prefix}_all_${file_type}_merged.nii.gz" ]]; then
                    mv "${output_prefix}_all_${file_type}_merged.nii.gz" "../merged/"
                fi
            else
                echo "    ✗ Error creating ${output_prefix}_all_${file_type}_merged.nii.gz" | tee -a "$LOG_FILE"
            fi
        else
            echo "    ⚠ No ${file_type} files found for merge" | tee -a "$LOG_FILE"
        fi
    }
    
    # Process positive files
    echo "Merging POSITIVE files..." | tee -a "$LOG_FILE"
    # Create all_positive merged file first
    merge_all_timepoints "positive" "${matches_dir##*/}"
    
    # Then process by time window
    echo -e "\nMerging POSITIVE files by time window..." | tee -a "$LOG_FILE"
    merge_by_window "early" "$EARLY_START" "$EARLY_END" "positive" "${matches_dir##*/}_positive_early" | tee -a "$LOG_FILE"
    merge_by_window "middle" "$MIDDLE_START" "$MIDDLE_END" "positive" "${matches_dir##*/}_positive_middle" | tee -a "$LOG_FILE"
    merge_by_window "late" "$LATE_START" "$LATE_END" "positive" "${matches_dir##*/}_positive_late" | tee -a "$LOG_FILE"
    
    # Process negative files
    echo -e "\nMerging NEGATIVE files..." | tee -a "$LOG_FILE"
    # Create all_negative merged file
    merge_all_timepoints "negative" "${matches_dir##*/}"
    
    # Then process by time window
    echo -e "\nMerging NEGATIVE files by time window..." | tee -a "$LOG_FILE"
    merge_by_window "early" "$EARLY_START" "$EARLY_END" "negative" "${matches_dir##*/}_negative_early" | tee -a "$LOG_FILE"
    merge_by_window "middle" "$MIDDLE_START" "$MIDDLE_END" "negative" "${matches_dir##*/}_negative_middle" | tee -a "$LOG_FILE"
    merge_by_window "late" "$LATE_START" "$LATE_END" "negative" "${matches_dir##*/}_negative_late" | tee -a "$LOG_FILE"
    
    # Change back to parent directory if we changed to individuals/
    if [[ -d "individuals" && "$(pwd)" == */individuals ]]; then
        cd ..
    fi
    
    # Process combined files (both positive and negative)
    echo -e "\nMerging COMBINED files..." | tee -a "$LOG_FILE"
    
    # Get all positive and negative files for combined processing
    all_combined_files=()
    
    # Add all positive files (check both current directory and individuals/ subdirectory)
    for file in *_positive_directionality.nii.gz individuals/*_positive_directionality.nii.gz; do
        if [[ -f "$file" ]]; then
            all_combined_files+=("$file")
        fi
    done
    
    # Add all negative files (check both current directory and individuals/ subdirectory)
    for file in *_negative_directionality.nii.gz individuals/*_negative_directionality.nii.gz; do
        if [[ -f "$file" ]]; then
            all_combined_files+=("$file")
        fi
    done
    
    # Create overall combined file (all timepoints)
    if [[ ${#all_combined_files[@]} -gt 0 ]]; then
        echo "  Merging ALL combined files (${#all_combined_files[@]} files)..." | tee -a "$LOG_FILE"
        output_file="${matches_dir##*/}_all_combined_merged.nii.gz"
        3dmerge -dxyz=1 -1clust 1 20 -prefix "$output_file" "${all_combined_files[@]}"
        if [[ $? -eq 0 ]]; then
            echo "    ✓ Successfully created $output_file" | tee -a "$LOG_FILE"
            # Move to merged directory if it exists
            if [[ -d "merged" && -f "$output_file" ]]; then
                mv "$output_file" "merged/"
                echo "    ✓ Moved to merged/$(basename "$output_file")" | tee -a "$LOG_FILE"
            fi
        else
            echo "    ✗ Error creating combined file" | tee -a "$LOG_FILE"
        fi
    else
        echo "    ⚠ No files found for combined merge" | tee -a "$LOG_FILE"
    fi
    
    # Also create windowed combined files
    echo -e "\nMerging COMBINED files by time window..." | tee -a "$LOG_FILE"
    merge_by_window "early" "$EARLY_START" "$EARLY_END" "combined" "${matches_dir##*/}_combined_early" | tee -a "$LOG_FILE"
    merge_by_window "middle" "$MIDDLE_START" "$MIDDLE_END" "combined" "${matches_dir##*/}_combined_middle" | tee -a "$LOG_FILE"
    merge_by_window "late" "$LATE_START" "$LATE_END" "combined" "${matches_dir##*/}_combined_late" | tee -a "$LOG_FILE"
    
    echo -e "\nCompleted processing: $matches_dir\n" | tee -a "$LOG_FILE"
done

echo -e "\nWindow merging process complete!" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE"
