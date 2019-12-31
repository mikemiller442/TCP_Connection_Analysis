#!/usr/bin/env python
# coding: utf-8

# In[3]:


import pandas as pd
import matplotlib.pyplot as plt


# In[4]:


# Loading in Data
df = pd.read_csv('./TCP_dataset3.csv')

# Dropping unwanted columns / minor last-minute cleaning
df = df.drop(columns = ['Unnamed: 0', 'X', 'ip_source', 'ip_addr', 'num_Resets', 'avg_Resets'])


# # Classification Only

# In[5]:


# Checking the amount of post_fin_resets equal to 0
sum(df['post_fin_resets'] == 0)


# In[6]:


from sklearn.model_selection import train_test_split

# Splitting data into features and target
features = df.drop(columns = ['post_fin_resets'])
target = df['post_fin_resets'] != 0

# Splitting into training and testing sets using random (unstratified) sampling
feat_train, feat_test, tar_train, tar_test = train_test_split(features, target, test_size = 0.1, random_state = 0)

# defining a function to plot a histogram
def histogram(data):
    count, division = pd.np.histogram(data)
    data.hist(bins = division)
    
# plotting histogram on native data
histogram(df['post_fin_resets'] != 0)
plt.title('Target Distribution')
plt.xlabel('Presence of 0 value Post-Fin Resets')
plt.ylabel('Frequency') 
plt.savefig('histogram_post_fin_resets.png', bbox_inches = 'tight', dpi = 600)


# # Proportioning Data

# In[7]:


# Code that resamples data, converting the 2:3 ratio into a 1:1 ratio

df_model = feat_train
df_model['post_fin_resets'] = tar_train

from sklearn.utils import resample

# randomly sampling target into 1:1 ratio
test_tar = resample(df_model[df_model['post_fin_resets'] == 0], 
                    n_samples = len(df_model[df_model['post_fin_resets'] != 0]))

# making a new dataframe that is proportioned
model_df = df_model[df_model['post_fin_resets'] != 0].append(test_tar)

# splitting dataframe again into features and target
model_features = model_df.drop(columns = ['post_fin_resets'])
model_target = model_df['post_fin_resets']


# # Model Testing Split

# In[8]:


# Splitting data into training and validation sets
#
# Idea is to keep test set pure. We can run cross validation etc on training and validation sets
# , so we can eliminate some bias
feat_train, feat_val, tar_train, tar_val = train_test_split(features, target
                                                            , test_size = 0.2, random_state = 0)
# checking target value again (in this case we used our original 2:3 split, as it yielded better results)
histogram(tar_val)


# # Modeling 

# In[9]:


from sklearn.ensemble import RandomForestClassifier

# true if postFinResets != 0
# false if postFinResets == 0

# To save time, used parameters that cross validation gave us so we don't have to run it again.

# defininig random forest classifier 
mod = RandomForestClassifier(n_estimators=1000, criterion = 'gini', min_samples_split=10, max_features='log2'
                             , random_state= 0, max_depth=5)
# fitting random forest
mod.fit(feat_train, tar_train)


# In[11]:


from sklearn.metrics import classification_report
from sklearn.metrics import cohen_kappa_score
from sklearn.metrics import balanced_accuracy_score
from sklearn.metrics import jaccard_score


# Predicting using model
tar_pred = mod.predict(feat_val)

# Printing out statistics for validation data
print(classification_report(tar_val, tar_pred))
print('kappa score: ' + str(cohen_kappa_score(tar_val, tar_pred)))
print(balanced_accuracy_score(tar_val, tar_pred))
print(jaccard_score(tar_val, tar_pred))


# # Final Testing

# In[12]:


# final testing on "unseen" data
tar_pred = mod.predict(feat_test)

# printing out statistics for model evaluation
print(classification_report(tar_test, tar_pred))
print('kappa score: ' + str(cohen_kappa_score(tar_test, tar_pred)))
print('balanced accuracy: ' + str(balanced_accuracy_score(tar_test, tar_pred)))


# In[13]:


# # code to plot tree
# from sklearn.externals.six import StringIO  
# #from IPython.display import Image  
# from sklearn.tree import export_graphviz
# import pydotplus

# dot_data = StringIO()
# # converting tree from text form into graphable form
# export_graphviz(mod.estimators_[513], out_file=dot_data,  
#                 filled=True, rounded=True,
#                 special_characters=True, feature_names = feat_train.columns)
# graph = pydotplus.graph_from_dot_data(dot_data.getvalue()) 

# # creating image from graph data
# #Image(graph.create_png())

# # saving to file
# with open("Tree.png", "wb") as png:
#     png.write((graph.create_png()))


# # In[26]:


import numpy as np

# Plotting feature importance on tree

# defining vars
col = feat_train.columns
y = mod.feature_importances_

#plotting figures
fig, ax = plt.subplots() 
ax.barh(np.arange(len(y)), y, 0.4, color= 'teal')

ax.set_yticks(np.arange(len(y))+0.4/10)
ax.set_yticklabels(col, minor=False)


# labelling axis
plt.title('Feature importance on Random Forest Estimators')
plt.xlabel('Relative importance')
plt.ylabel('feature') 

plt.figure(figsize=(5,5))

# saving figure
fig.savefig('feat_importance.png', bbox_inches = 'tight', dpi = 600)

