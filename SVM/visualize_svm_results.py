# July 25
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Manually create the DataFrame from the data
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
df['Significance'] = ['**' if p < 0.01 else '*' if p < 0.05 else '' for p in df['CV_P_Value']]
df['Is_Significant'] = df['CV_P_Value'] < 0.05

# Sort by CV_Accuracy in descending order
df = df.sort_values('CV_Accuracy', ascending=False).reset_index(drop=True)

# Display the DataFrame
print("SVM Analysis Results:")
print(df)

# Create visualizations
plt.figure(figsize=(10, 6))
sns.barplot(data=df, x='Category', y='CV_Accuracy', errorbar='sd', color='#4caf50')
plt.title('Cross-Validation Accuracy by Category')
plt.xticks(rotation=45, ha='right')
plt.ylabel('CV Accuracy')
plt.tight_layout()
plt.savefig('cv_accuracy_plot.png')
plt.show()

# Create a more detailed plot with significance indicators
plt.figure(figsize=(12, 6))
ax = sns.barplot(data=df, x='Category', y='CV_Accuracy', errorbar='sd',
                order=df.sort_values('CV_Accuracy', ascending=False)['Category'],
                color='#4caf50')
plt.ylabel('CV Accuracy')

# Add error bars manually to ensure they're visible with the limited y-range
for i, (_, row) in enumerate(df.iterrows()):
    plt.errorbar(x=i, y=row['CV_Accuracy'],
                yerr=row['CV_Std'],
                color='black', capsize=5, capthick=2, linewidth=2)

plt.ylim(0.3, 0.9)
plt.axhline(y=0.5, color='red', linestyle='-', linewidth=1, label='Chance Level')
plt.xticks(rotation=45, ha='right')
plt.title('Cross-Validation Accuracy with Standard Deviation')
plt.tight_layout()
plt.savefig('cv_accuracy_with_std.png')
plt.show()

print("Visualizations have been saved as 'cv_accuracy_plot.png' and 'cv_accuracy_with_std.png'")
