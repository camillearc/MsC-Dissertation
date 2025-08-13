import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Data from the latest analysis
data = {
    'Category': ['Negative', 'Past', 'Positive', 'Cognitive', 'Physical', 'Present', 'First'],
    'CV_Accuracy': [0.5699, 0.5477, 0.5222, 0.4987, 0.4895, 0.4654, 0.4405],
    'CV_Std': [0.0942, 0.0934, 0.0737, 0.1133, 0.0999, 0.0386, 0.1140],
    'LOO_Accuracy': [0.5814, 0.6047, 0.4767, 0.4070, 0.4767, 0.5581, 0.4070],
    'CV_P_Value': [0.1479, 0.2148, 0.4186, 0.5365, 0.5854, 0.6883, 0.8531],
    'LOO_P_Value': [0.0792, 0.0495, 0.6832, 0.9307, 0.6931, 0.2277, 0.9307]
}

# Create the DataFrame
df = pd.DataFrame(data)

# Add significance column
df['Significance'] = ['**' if p < 0.01 else '*' if p < 0.05 else '' for p in df['LOO_P_Value']]
df['Is_Significant'] = df['LOO_P_Value'] < 0.05

# Sort by LOO_Accuracy in descending order
df = df.sort_values('LOO_Accuracy', ascending=False).reset_index(drop=True)

# Display the DataFrame
print("LOO Analysis Results:")
print(df[['Category', 'LOO_Accuracy', 'LOO_P_Value', 'Significance']])

# Create visualizations for LOO results
plt.figure(figsize=(10, 6))
ax = sns.barplot(data=df, x='Category', y='LOO_Accuracy', 
                order=df.sort_values('LOO_Accuracy', ascending=False)['Category'],
                color='#4caf50')

# Add values on top of bars
for i, v in enumerate(df['LOO_Accuracy']):
    ax.text(i, v + 0.01, f"{v:.4f}", ha='center')

plt.axhline(y=0.5, color='red', linestyle='--', linewidth=1, label='Chance Level')
plt.ylim(0.4, 0.6)  # Adjusted y-axis to better show LOO accuracies
plt.xticks(rotation=45, ha='right')
plt.title('Leave-One-Out Cross-Validation Accuracy by Category')
plt.ylabel('LOO Accuracy')
plt.legend()
plt.tight_layout()
plt.savefig('loo_accuracy_plot.png')
plt.show()

# Create a comparison plot between CV and LOO accuracies
plt.figure(figsize=(12, 6))
bar_width = 0.35
index = np.arange(len(df))

# Plot CV accuracies
cv_bars = plt.bar(index - bar_width/2, df['CV_Accuracy'], bar_width, 
                 label='5-Fold CV', color='#9e9e9e', alpha=0.7)

# Plot LOO accuracies
loo_bars = plt.bar(index + bar_width/2, df['LOO_Accuracy'], bar_width, 
                  label='LOO CV', color='#4caf50', alpha=0.7)

# Add significance markers
for i, (_, row) in enumerate(df.iterrows()):
    if row['Significance']:
        plt.text(i, max(row['CV_Accuracy'], row['LOO_Accuracy']) + 0.02, 
                row['Significance'], ha='center')

plt.axhline(y=0.5, color='red', linestyle='--', linewidth=1, label='Chance Level')
plt.xticks(index, df['Category'], rotation=45, ha='right')
plt.ylim(0.3, 0.9)
plt.title('Comparison of 5-Fold CV and LOO CV Accuracies')
plt.ylabel('Accuracy')
plt.legend()
plt.tight_layout()
plt.savefig('cv_vs_loo_comparison.png')
plt.show()

print("Visualizations have been saved as 'loo_accuracy_plot.png' and 'cv_vs_loo_comparison.png'")
