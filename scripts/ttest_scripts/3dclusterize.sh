#!/bin/bash

# Clusterize directionality maps
# This script processes both individual timepoints and windowed files

# Base directory containing all the data
BASE_DIR="/data/carcher/ttest_analysis_v2/ttest_output"

# Output directory for cluster tables
OUTPUT_DIR="/data/carcher/cluster_analysis"

# Create output directories
mkdir -p "$OUTPUT_DIR/windowed_analysis"
# Individual timepoints directories will be created per-category

# File to store all windowed analysis results
WINDOWED_SUMMARY="$OUTPUT_DIR/windowed_analysis/all_windows_summary.1D"
echo "# Cluster analysis summary for all windowed analyses" > "$WINDOWED_SUMMARY"
echo "# Generated: $(date)" >> "$WINDOWED_SUMMARY"
echo "#" >> "$WINDOWED_SUMMARY"

# Function to run 3dClusterize and save results
run_clusterize() {
    local input_file="$1"
    local output_file="$2"
    local threshold=0.0001  # Adjust as needed
    
    echo "Processing $input_file"
    
    3dClusterize \
        -nosum \
        -1Dformat \
        -inset "$input_file" \
        -idat 0 \
        -ithr 0 \
        -NN 2 \
        -clust_nvox 40 \
        -bisided \
        -$threshold $threshold \
        > "$output_file"
        
    echo "  -> Results saved to $output_file"
}

# Function to process individual timepoints
process_individual_timepoints() {
    local matches_dir="$1"
    local category
    # Extract the category name from the path (e.g., /path/to/cognitive/matches -> cognitive)
    category=$(basename "$(dirname "$matches_dir")")
    local individuals_dir="$matches_dir/merged_outputs/individuals"
    
    # Skip if no individuals directory exists
    [ ! -d "$individuals_dir" ] && { echo "  No individuals directory found in $matches_dir/merged_outputs/"; return; }
    
    echo -e "\n=== Processing individual timepoints for $category ==="
    
    # Create output directory for this category
    mkdir -p "$OUTPUT_DIR/individual_timepoints/$category"
    
    # Count the number of files found
    local positive_files=("$individuals_dir"/*_positive_directionality.nii.gz)
    local negative_files=("$individuals_dir"/*_negative_directionality.nii.gz)
    
    echo "  Found ${#positive_files[@]} positive directionality files"
    echo "  Found ${#negative_files[@]} negative directionality files"
    
    # Process positive directionality files
    for file in "${positive_files[@]}"; do
        [ ! -f "$file" ] && continue
        
        base_name=$(basename "$file" .nii.gz)
        output_file="$OUTPUT_DIR/individual_timepoints/$category/${base_name}_clusters.1D"
        run_clusterize "$file" "$output_file"
    done
    
    # Process negative directionality files
    for file in "${negative_files[@]}"; do
        [ ! -f "$file" ] && continue
        
        base_name=$(basename "$file" .nii.gz)
        output_file="$OUTPUT_DIR/individual_timepoints/$category/${base_name}_clusters.1D"
        run_clusterize "$file" "$output_file"
    done
}



###THE PROBLEM - it only created window summary files for the 'ttest_output' directory as a whole - need it to go down one more level
# so that it is doing this for the 8 word categories

# Function to process windowed files
process_windowed_files() {
    local matches_dir="$1"
    local category
    # Extract the category name from the path (e.g., /path/to/cognitive/matches -> cognitive)
    category=$(basename "$(dirname "$matches_dir")")
    local merged_dir="$matches_dir/merged_outputs/merged"
    
    # Skip if no merged directory exists
    [ ! -d "$merged_dir" ] && { echo "  No merged directory found in $matches_dir/merged_outputs/"; return; }
    
    echo -e "\n=== Processing windowed files for $category ==="
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR/windowed_analysis"
    
    # Create a summary file for this category's windowed analyses
    local category_summary="$OUTPUT_DIR/windowed_analysis/${category}_windows_summary.1D"
    echo "# Cluster analysis summary for $category" > "$category_summary"
    echo "# Generated: $(date)" >> "$category_summary"
    echo "#" >> "$category_summary"
    
    # Process each window type (positive, negative, combined)
    for type in positive negative combined; do
        # Process each time window (early, middle, late, all)
        for window in early middle late all; do
            # Handle different file naming patterns
            if [ "$window" == "all" ]; then
                if [ "$type" == "combined" ]; then
                    file="$merged_dir/matches_all_combined_merged.nii.gz"
                else
                    file="$merged_dir/matches_all_${type}_merged.nii.gz"
                fi
            else
                if [ "$type" == "combined" ]; then
                    file="$merged_dir/matches_${type}_${window}.nii.gz"
                else
                    file="$merged_dir/matches_${type}_${window}.nii.gz"
                fi
            fi
            
            # Skip if file doesn't exist
            [ ! -f "$file" ] && { 
                echo "  File not found: $file"; 
                continue; 
            }
            
            echo "Processing window: $type $window"
            echo "  Input file: $file"
            
            output_file="$OUTPUT_DIR/windowed_analysis/${category}_${type}_${window}_clusters.1D"
            run_clusterize "$file" "$output_file"
            
            # Add to category summary
            echo -e "\n# Window: $window - $type" >> "$category_summary"
            if [ -s "$output_file" ] && [ $(wc -l < "$output_file") -gt 5 ]; then
                cat "$output_file" >> "$category_summary"
            else
                echo "No significant clusters found" >> "$category_summary"
            fi
            
            # Add to global summary
            echo -e "\n# Category: $category - Window: $window - $type" >> "$WINDOWED_SUMMARY"
            if [ -s "$output_file" ] && [ $(wc -l < "$output_file") -gt 5 ]; then
                cat "$output_file" >> "$WINDOWED_SUMMARY"
            else
                echo "No significant clusters found" >> "$WINDOWED_SUMMARY"
            fi
        done
    done
}




# Main execution
main() {
    echo "Starting cluster analysis of directionality maps..."
    
    # Process each category directory in ttest_output
    for category_dir in "$BASE_DIR"/*/; do
        # Skip if not a directory or if it's the scripts directory
        [[ ! -d "$category_dir" || "$category_dir" == *"scripts"* ]] && continue
        
        category=$(basename "$category_dir")
        echo -e "\n=== Processing category: $category ==="
        
        # Process the matches directory for this category
        matches_dir="$category_dir/matches"
        if [ -d "$matches_dir" ]; then
            process_individual_timepoints "$matches_dir"
            process_windowed_files "$matches_dir"
        else
            echo "Warning: No matches directory found in $category_dir"
        fi
    done
    
    echo -e "\nAll done! Cluster analysis complete."
    echo "Individual timepoints saved to: $OUTPUT_DIR/individual_timepoints/"
    echo "Windowed analysis saved to: $OUTPUT_DIR/windowed_analysis/"
}

# Run the main function
main "$@"
