### SCRIPT THAT WORKED TO RUN THE INDIVIDUAL MAPS - backup version

#!/usr/bin/env python3
"""
Script to visualize NIfTI files from merged_maps directories using nilearn's surface plotting.
"""
import os
import glob
import numpy as np
import matplotlib.pyplot as plt
from nilearn import plotting
import nibabel as nib
import gc  # For garbage collection
from pathlib import Path
from matplotlib import ticker  # For better tick formatting

def find_nii_files(base_dir):
    """Find all .nii.gz files in merged_maps subdirectories."""
    search_pattern = os.path.join(base_dir, '**/merged_maps/matches_combined_*.nii.gz')
    print(f"\nSearching for NIfTI files using pattern: {search_pattern}")
    files = glob.glob(search_pattern, recursive=True)
    if files:
        print("\nFound the following NIfTI files:")
        for i, f in enumerate(files, 1):
            print(f"{i}. {f}")
    return files

def create_visualization(nii_file):
    """Create and save surface visualization for a NIfTI file."""
    try:
        # Check if file exists before proceeding
        if not os.path.exists(nii_file):
            print(f"File not found: {nii_file}")
            return
            
        # Get the parent directory name for context
        parent_dir = os.path.basename(os.path.dirname(os.path.dirname(nii_file)))
        
        # Create output directory only if file exists
        output_dir = os.path.join('visualizations', parent_dir, os.path.basename(nii_file).replace('.nii.gz', ''))
        output_file = os.path.join(output_dir, 'surface_plot.png')
        
        # Format the title - remove 'matches_combined' and clean up
        clean_name = os.path.basename(nii_file).replace('_', ' ').replace('.nii.gz', '')
        clean_name = clean_name.replace('matches combined', '').strip(' -_')
        # Capitalize the timepoint (early/middle/late) in the title
        for timepoint in ['early', 'middle', 'late']:
            if timepoint in clean_name.lower():
                clean_name = clean_name.lower().replace(timepoint, timepoint.capitalize())
                break
        title = f"{parent_dir.replace('_', ' ').title()}: {clean_name}"
        
        # Load the NIfTI file to check its properties
        import nibabel as nib
        import numpy as np
        
        # Load the image
        img = nib.load(nii_file)
        data = img.get_fdata()
        
        # Print debug information
        print(f"\nFile: {nii_file}")
        print(f"Data shape: {data.shape}")
        print(f"Data range: {np.nanmin(data):.2f} to {np.nanmax(data):.2f}")
        print(f"Non-zero values: {np.count_nonzero(data)} / {data.size} ({np.count_nonzero(data)/data.size*100:.2f}%)")
        
        # No threshold - show all data
        threshold = None
        print("No threshold applied - showing all data")
        
        # Create a new figure with larger size
        fig = plt.figure(figsize=(16, 8))
        
        # Calculate vmax based on data range for better contrast
        # Use a higher percentile to make clusters more visible
        abs_data = np.abs(data[data != 0])
        if len(abs_data) > 0:
            data_max = np.percentile(abs_data, 99)  # Use 99th percentile for better contrast
        else:
            data_max = 0.01
        vmax = max(0.01, data_max * 1.2)  # Add 20% more contrast
        
        # Create a new figure with larger size
        fig = plt.figure(figsize=(16, 8))
        
        # Create a larger figure to accommodate the colorbar
        fig = plt.figure(figsize=(20, 12))
        
        # Create the plot with built-in colorbar
        plotting.plot_img_on_surf(
            stat_map=nii_file,
            views=['lateral', 'medial'],
            hemispheres=['left', 'right'],
            title=title,
            bg_on_data=True,
            colorbar=True,
            threshold=1e-4,
            cmap='bwr',
            vmax=vmax,
            cbar_tick_format=""
        )
        
        # Create output directory only if visualization is successful
        os.makedirs(output_dir, exist_ok=True)
        
        # Save and close the figure
        plt.savefig(output_file, bbox_inches='tight', dpi=150, facecolor='white')
        plt.close(fig)  # Close the current figure
        plt.close('all')  # Close all other open figures
        gc.collect()  # Force garbage collection
        print(f"Created visualization: {output_file}")
        
    except Exception as e:
        print(f"Error processing {nii_file}: {str(e)}")
        plt.close()

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    nii_files = find_nii_files(base_dir)
    
    if not nii_files:
        print("\nNo NIfTI files found in merged_maps directories.")
        print("Searched in:", os.path.abspath(os.path.join(base_dir, '**/merged_maps/')))
        return
    
    print(f"Found {len(nii_files)} NIfTI files to process.")
    
    # Create visualizations directory if it doesn't exist
    os.makedirs('visualizations', exist_ok=True)
    
    # Process each file
    for nii_file in nii_files:
        print(f"Processing: {nii_file}")
        create_visualization(nii_file)

if __name__ == "__main__":
    main()
