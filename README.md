# Employment Status Analysis Project

## Overview
This project conducts a comprehensive analysis of employment status data from Denmark's Statistikbanken, examining the relationship between demographic characteristics (sex, age, education level) and employment outcomes. The analysis progresses from aggregate-level descriptive statistics to individual-level predictive modeling.

## Project Structure

### 📁 0) Data
- **`raw_data.csv`** - Original dataset from Statistikbanken containing employment status counts by demographic groups
- **`dataextractionmethod.pdf`** - Documentation of data extraction methodology

### 📁 1) Preprocessing
- **`preprocessing.sas`** - Data cleaning and transformation script
- **`aggregate_data.csv`** - Processed aggregate-level data for group analysis
- **`individual_data.csv`** - Expanded individual-level dataset (113MB)
- **`preprocessingresults.pdf`** - Printout of results/output from preprocessing.sas

**Key Transformations:**
- Simplified demographic variables (sex, age groups, education levels)
- Collapsed employment statuses into 5 main categories:
  - Employed
  - Unemployed
  - In Education or Training
  - On Pension
  - Not in Labor Force
- Expanded aggregate counts to individual-level observations (~5 million records)

### 📁 2) Sampling
- **`sampling.sas`** - Stratified sampling methodology
- **`stratified_individual_sample.csv`** - 10% stratified sample for individual analysis
- **`samplingresults.pdf`** - Printout of results/output from sampling.sas

**Sampling Strategy:**
- Three-way stratified sampling by sex, age group, and education level
- Maintains demographic representativeness of original population
- Enables efficient individual-level analysis on manageably sized dataset

### 📁 3) Aggregate Analysis
- **`aggregateanalysis.sas`** - Group-level descriptive analysis
- **`aggregateanalysisresults.pdf`** - Printout of results/output from aggregateanalysis.sas

**Analysis Components:**
- Employment status distribution across demographic groups
- Cross-tabulations and frequency analyses
- Stacked bar charts visualizing employment patterns
- Three-way analysis of employment status by education, age, and sex

### 📁 4) Individual Analysis: 
NOTE: So far, I've only been able to get the code to WORK, to try various functions that can be used to analyze individual-level
data. I have not yet thought through exactly WHICH individual analysis methods suit my discrete multivariate data, nor understood how to interpret the results. I've been able to do this for all the previous steps (Data, Preprocessing, Sampling and Aggregate Analysis) but not yetthis Individual Analysis step.

### Running the Analysis
1. **Data Preparation**: Ensure raw data is in `0)Data/raw_data.csv`
2. **Sequential Execution**: Run SAS scripts in numerical order:
   ```bash
   # Preprocessing
   sas preprocessing.sas
   
   # Sampling
   sas sampling.sas
   
   # Aggregate Analysis
   sas aggregateanalysis.sas
   
   # Individual Analysis
   sas individualanalysis.sas

### Software Stack
- **SAS**: Primary statistical analysis platform
- **Bash**: File management and Git operations
- **Git LFS**: Large file version control

### Prerequisites
- SAS software with appropriate licenses
- Git with LFS support
- Sufficient storage for large datasets (~150MB total)
   ```
3. **Results Review**: Check generated PDF files for comprehensive results

## File Management
- **`cleanup_large_file.sh`** - Script for managing large files with Git LFS
- **`.gitattributes`** - Git LFS configuration for large data files
