# Clean Data #

# This script will take the CSV file "FY2012 General Fund Full-Monty Budget.csv" and do some basic data
# cleaning to make it ready for cubes and D3. Assumes that "FY2012 General Fund Full-Monty Budget.csv" is
# in a subdirectory of the directory of this file called "Data" (eg. "./Data/FY2012 General Fund Full-Monty Budget.csv")

# There are a few things that need to be done:

#     - Standardize capitalization of Department names
#     - Deal with near-duplicate issues like "Police" and "Police Department"
#     - Remove commas from expenditure column so the column is properly recognized as a float/real

# When these 2 tasks are finished, data will be exported to a csv file
# ## Load Pandas and Data ##
# Load pandas - a data analysis library for python - and read in data while removing NAs

from pandas import merge
from string import join, capwords, replace
import pandas as pd
import re

header_row = ['fy', 'dep_id', 'dep_name', 'sub_obj_id', 'sub_obj_name',
    'vendor_name', 'transaction_description', 'last_name', 'first_name',
    'middle_initial', 'pay_class_title', 'total_ex']
raw_data = pd.read_csv("./Data/FY2012 General Fund Full-Monty Budget.csv",
    names=header_row, skiprows=1)
raw_data_clean = raw_data.fillna('UNKNOWN or NONE')

# Correct case for pay classes.

capitalized_pay_class = []
cased = [capwords(x) for x in raw_data_clean.pay_class_title]

raw_data_clean.pay_class_title = cased

# Fix format of Department Name and Subject Names

capitalized_dep_name = [capwords(x) for x in raw_data_clean.dep_name]

raw_data_clean.dep_name = capitalized_dep_name

capitalized_subjects = []
cased = [capwords(x) for x in raw_data_clean.sub_obj_name]
sub_nodigits = [re.sub("\s+\d+$", "", x) for x in cased]

raw_data_clean.sub_obj_name = sub_nodigits

capitalized_vendors = []
cased = [capwords(x) for x in raw_data_clean.vendor_name]
for x in cased:
    if re.search(r'\s{2,}\d+$', x):
        capitalized_vendors.append(join(x.split()[:-2]))
    else:
        capitalized_vendors.append(x)

raw_data_clean.vendor_name = capitalized_vendors

capitalized_trans_desc = []
cased = [capwords(x) for x in raw_data_clean.transaction_description]
for x in cased:
    if re.search(r'\s{2,}\d+$', x):
        capitalized_trans_desc.append(join(x.split()[:-2]))
    else:
        capitalized_trans_desc.append(x)

raw_data_clean.transaction_description = capitalized_trans_desc

# Remove commas from expenditure data.

raw_data_clean['total_ex'] = [replace(x, ',', '') for x in raw_data_clean.total_ex]
raw_data_clean['total_ex'] = [replace(x, '(', '-') for x in raw_data_clean.total_ex]
raw_data_clean['total_ex'] = [replace(x, ')', '') for x in raw_data_clean.total_ex]

# Next we split up the data to remove duplicates and be able to normalize the data for import into a database. Tables are created for the following:
# - Departments with Department IDs
# - Subjects and Subject IDs

# After separating out the data we drop the duplicate rows to only keep the unique values which we will either now have keys or we will generate ourselves.

depts = raw_data_clean.ix[:, ['dep_name', 'dep_id']]
subjs = raw_data_clean.ix[:, ['sub_obj_id', 'sub_obj_name']]

# Drop Duplicates #
depts_nd = depts.drop_duplicates(['dep_id'])
subjs_nd = subjs.drop_duplicates(['sub_obj_id'])

# Drop the "name" columns that we know have duplicates and merge on ID columns after duplicates have been removed.

merged = raw_data_clean[['fy', 'dep_id', 'sub_obj_id', 'transaction_description',
    'last_name', 'first_name', 'middle_initial', 'pay_class_title', 'vendor_name', 'total_ex']]

merged = merge(merged, depts_nd, how='outer', on=['dep_id'])
merged = merge(merged, subjs_nd, how='outer', on=['sub_obj_id'])

# Save full table as .csv file

cols_to_export = ['fy', 'dep_name', 'dep_id', 'sub_obj_name', 'sub_obj_id',
    'vendor_name', 'transaction_description', 'middle_initial', 'last_name', 'first_name',
    'pay_class_title', 'total_ex']

merged.to_csv('./Data/full_table.csv', index=False, cols=cols_to_export)
