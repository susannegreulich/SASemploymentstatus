/* Set up destination pdf file for saving all SAS results. 
The Listing style keeps formatting exactly as printed in SAS. */
ODS PDF FILE='/home/u64257150/EmploymentStatus/2)Sampling/samplingresults.pdf' STYLE=LISTING;

/* Import individual-level data with proper length specifications*/
DATA individual_data;
    INFILE '/home/u64257150/EmploymentStatus/1)Preprocessing/individual_data.csv' DSD FIRSTOBS=2;
    LENGTH sex $1 age_group $6 education_level $6 employment_status $25;
    INPUT sex $ age_group $ education_level $ employment_status $;
RUN;
/* This full individual-level data set is VERY LARGE, with nearly 5 mio observations. 
As I write my code for individual-level data analysis, testing it on the full dataset would take a 
LOT of time for each iteration, because of its size.  So I will take a smaller sample, SUBSET, of 
this full individual dataset, in order to test my code on.*/

/* I want to take a random sample that is STRATIFIED by the 3 variables sex, age and education, as 
these are supposedly/theoretically the independent variables which can influence the dependent 
variable of employment_status. Stratifying maintains the original total population's relative 
distribution of these demographic characteristics. This thus also maintains the joint distribution
of predictors, and is better for multivariate analysis, e.g., logistic regression. Stratified sampling divides the total population into subgroups (strata) and 
samples from each subgroup separately. This maintains the distribution of key variables in the 
sample and guarantees representation from all categories. But stratifying by MANY variables has the
potential downside of creating permutations (combinations of variable values) with very low counts.
So I must first make sure that the counts for all possible 3-way permutations are high enough.*/

/* Count observations in each 3-way combination, and look at the ones with lowest counts.*/
proc sql;
    title "Count of Observations in Each 3-Way Combination";
    select 
        sex,
        age_group,
        education_level,
        count(*) as obs_count
    from individual_data
    group by sex, age_group, education_level
    order by obs_count desc;
quit;

proc sql;
    title "Summary of 3-Way Combinations";
    select 
        count(*) as total_combinations,
        sum(case when obs_count >= 10 then 1 else 0 end) as combinations_with_10plus,
        sum(case when obs_count < 10 then 1 else 0 end) as combinations_with_less_than_10,
        sum(case when obs_count < 5 then 1 else 0 end) as combinations_with_less_than_5
    from (
        select 
            sex,
            age_group,
            education_level,
            count(*) as obs_count
        from individual_data
        group by sex, age_group, education_level
    );
quit;

/* The results show that the 3-way permutation with LOWEST count has 379 observations, which
is more than adequate for three-way stratification. So I proceed with 3-way stratification.
Sort the data by the 3 stratifying variables before proceeding with stratification. This is
because SAS procedures are sensitive to order. */
PROC SORT DATA=individual_data;
	BY sex age_group education_level;
RUN;

/* Implement three-way stratified 10% sampling, stratified by sex, age and education, 
randomly sampled within each group.*/
proc surveyselect data=individual_data 
    out=individual_data_sample
    method=srs 
    samprate=0.1; /* Taking a 10% sample to ensure adequate cell sizes */
    strata sex age_group education_level;  /* Three-way stratification */
run;

/* Verify the stratification results */
proc sql;
    title "Verification of Cell Sizes in Stratified Sample";
    select 
        sex,
        education_level,
        age_group,
        count(*) as sample_count
    from individual_data_sample
    group by sex, education_level, age_group
    order by sample_count;
quit;

/* Compare distributions between original and sampled data */
proc freq data=individual_data;
    tables sex education_level age_group;
    title "Original Data Distributions";
run;

proc freq data=individual_data_sample;
    tables sex education_level age_group;
    title "Stratified Sample Distributions";
run;
/* The relative distributions of the demographic characteristics are SIMILAR in the sample and the 
original data, so we can be sure that the sample is demographically representative of the full 
dataset/population. We can proceed to testing and applying individual-level analysis tools to this 
sample. This will be done in the separate individualanalysis.sas script.*/

/* Export the stratified sample */
proc export data=individual_data_sample(drop=SelectionProb SamplingWeight)
    outfile='/home/u64257150/EmploymentStatus/2)Sampling/stratified_individual_sample.csv'
    dbms=csv 
    replace;
run;

title; 

/* Close the PDF destination */
ODS PDF CLOSE;