#!/usr/bin/env python3
"""
Script to create glass brain visualizations for NIfTI files in category directories.
Finds files in the pattern: ttest_analysis_v2/ttest_output/*/matches/merged_outputs/merged/matches_combined_*.nii.gz
"""

import os
import glob
from nilearn import plotting
import matplotlib.pyplot as plt

def find_combined_niftis(base_path):
    """Find all NIfTI files matching 'matches_combined_*.nii.gz' in the ttest_output category directories."""
    search_pattern = os.path.join(
        base_path,
        'ttest_analysis_v2',
        'ttest_output',
        '*',  # category directory
        'matches',
        'merged_outputs',
        'merged',
        'matches_combined_*.nii.gz'  # match the specific pattern
    )
    return glob.glob(search_pattern)

def create_glass_brain(nifti_path, output_dir):
    """Create and save a glass brain visualization for a NIfTI file."""
    # Create output filename based on input path
    base_name = os.path.basename(nifti_path).replace('.nii.gz', '').replace('.nii', '')
    output_path = os.path.join(output_dir, f"{base_name}_glassbrain.png")
    
    # Create the output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    try:
        # Create a clean title by removing 'matches' and 'merged' and formatting the text
        title = base_name.replace('_', ' ').title().replace('Nii', 'NIfTI')
        title = title.replace('Matches', '').replace('Merged', '').strip()  # Remove 'Matches' and 'Merged' and any extra spaces
        
        # Create figure with adjusted layout and larger title
        fig = plt.figure(figsize=(14, 7))  # Slightly larger figure
        plt.suptitle(title, fontsize=14, y=0.97, x=0.1, ha='left', va='bottom', 
                    fontweight='bold')  # Increased font size and made it bold
        
        # Create the glass brain plot
        # First, let's load the data to check its range
        from nilearn import image
        img = image.load_img(nifti_path)
        data = img.get_fdata()
        
        # Set vmax to the absolute maximum value for symmetric scaling
        vmax = max(abs(data.min()), abs(data.max()))
        
        display = plotting.plot_glass_brain(
            nifti_path,
            display_mode='lyrz',  # sagittal, coronal, axial, and a 3D view
            colorbar=True,
            title='',  # We'll handle the title separately
            figure=fig,
            cmap='bwr',  # Blue-White-Red colormap
            vmin=-vmax,  # Set symmetric vmin/vmax
            vmax=vmax,
            threshold=1e-6,  # Small threshold to better visualize weak activations
            black_bg=False,  # Better contrast for the title
            plot_abs=False  # Show both positive and negative values
        )
        
        # Adjust layout to prevent overlap
        plt.tight_layout(rect=[0, 0, 1, 0.95])
        
        # Save the figure
        plt.savefig(output_path, bbox_inches='tight', dpi=150)
        plt.close()
        print(f"Created: {output_path}")
        return True
    except Exception as e:
        print(f"Error processing {nifti_path}: {str(e)}")
        return False

def main():
    base_path = '/data/carcher'
    output_base = os.path.join(base_path, 'glassbrain_outputs')
    
    # Find all matching NIfTI files
    nifti_files = find_combined_niftis(base_path)
    
    if not nifti_files:
        print("No NIfTI files with 'combined' in their name were found.")
        return
    
    print(f"Found {len(nifti_files)} NIfTI files to process.")
    
    # Process each file
    success_count = 0
    for nifti_path in nifti_files:
        # Create a subdirectory based on the category
        path_parts = nifti_path.split(os.sep)
        category_idx = path_parts.index('ttest_output') + 1
        category = path_parts[category_idx]
        output_dir = os.path.join(output_base, category)
        
        if create_glass_brain(nifti_path, output_dir):
            success_count += 1
    
    print(f"\nProcessing complete. Successfully created {success_count}/{len(nifti_files)} glass brain visualizations.")
    print(f"Output saved to: {output_base}")

if __name__ == "__main__":
    main()
