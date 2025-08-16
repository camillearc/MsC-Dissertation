#!/usr/bin/env python3
"""
Script to run atlasreader on NIfTI files in the ttest_analysis_v2/ttest_output/*/matches/merged_outputs directories.
Files are expected to be in the format {time}_{time}.nii.gz
"""
import os
import glob
import subprocess
from pathlib import Path

def run_atlasreader(input_file, output_dir):
    """Run atlasreader on a single NIfTI file."""
    print(f"Processing: {input_file}")
    try:
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Run atlasreader with minimal output (just the cluster tables)
        cmd = [
            'atlasreader',
            input_file,
            '40',  # min_cluster_size (positional argument)
            '--outdir', output_dir,
            '--threshold', '0.001',  # Cluster-forming threshold
            '--direction', 'both'  # Look at both positive and negative values
        ]
        
        print(f"Running command: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Error processing {input_file}:")
            print(f"Return code: {result.returncode}")
            print("=== STDOUT ===")
            print(result.stdout)
            print("=== STDERR ===")
            print(result.stderr)
            print("==============")
        else:
            print(f"Successfully processed {input_file}")
            print("=== Output ===")
            print(result.stdout)
            
    except Exception as e:
        print(f"Exception while processing {input_file}: {str(e)}")
        import traceback
        traceback.print_exc()

def main():
    base_dir = "/data/carcher/ttest_analysis_v2/category_vs_category/merged_outputs/merged"
    comparisons = [
        'negative_vs_positive', 'past_vs_present', 'perception_vs_physical', 'first_vs_cognitive'
    ]
    
    for comparison in categories:
        search_path = os.path.join(
            base_dir, 'comparison', 'merged_outputs', 'merged', '*_*.nii*'
        )
        
        for nii_file in glob.glob(search_path):
            # Get the time window from filename (e.g., 'early_early' from 'early_early.nii.gz')
            time_window = Path(nii_file).stem.replace('.nii', '')
            
            # Create output directory: atlasreader_outputs/{category}/{time_window}
            output_dir = os.path.join(
                os.path.dirname(nii_file),
                '..', '..', '..',  # Move up to ttest_output/category/
                'atlasreader_outputs',
                category,
                time_window
            )
            
            # Run atlasreader
            run_atlasreader(nii_file, output_dir)

if __name__ == "__main__":
    main()
