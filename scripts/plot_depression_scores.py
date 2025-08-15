import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Set style for better-looking plots
sns.set(style="whitegrid")
plt.figure(figsize=(14, 7))

# Read the Excel file
df = pd.read_excel('Depression_scores.xlsx')

# Sort by Subject ID for better visualization
df_sorted = df.sort_values('Subject ID')

# Calculate median T-score
median_t = df['TScore'].median()

# Create the plot
plt.figure(figsize=(14, 7))
plt.plot(df_sorted['Subject ID'], df_sorted['TScore'], 
         marker='o', linestyle='-', linewidth=2, markersize=8,
         color='#8B0000',  # Dark red color
         label='T-Score')

# Add median reference line
plt.axhline(y=median_t, color='#1f77b4', linestyle='--', linewidth=2, 
            alpha=0.8, label=f'Median T-Score ({median_t:.1f})')

# Customize the plot
plt.title('NIH Sadness/Depression CAT T-Scores by Participant', fontsize=16, pad=20)
plt.xlabel('Participant ID', fontsize=12)
plt.ylabel('T-Score', fontsize=12)
plt.xticks(rotation=45)
plt.legend()
plt.tight_layout()

# Add grid for better readability
plt.grid(True, alpha=0.3)

# Save the plot
plt.savefig('depression_scores_plot.png', dpi=300, bbox_inches='tight')
print("Plot saved as 'depression_scores_plot.png'")
