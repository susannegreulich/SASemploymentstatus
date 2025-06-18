/* Set up destination pdf file for saving all SAS results. 
The Listing style keeps formatting exactly as printed in SAS. */
ODS PDF FILE='/home/u64257150/EmploymentStatus/3)AggregateAnalysis/aggregateanalysisresults.pdf' STYLE=LISTING;

/* Import CSV file with proper length specifications
DATA aggregate_data;
    INFILE '/home/u64257150/Data/aggregate_data.csv' DSD FIRSTOBS=2;
    LENGTH sex $1 education_level $6 employment_status $25 age_group $6;
    INPUT sex $ education_level $ count employment_status $ age_group $;
RUN;*/

/* Step 1: Import aggregate data, with appropriate lengths and formats.*/
DATA aggregate_data;
    INFILE '/home/u64257150/EmploymentStatus/1)Preprocessing/aggregate_data.csv' DLM=',' FIRSTOBS=2;
    INPUT sex :1. age_group :$10. education_level :$10. employment_status :$25. count;
RUN;

/* We are interested in the employment status, and what influences it. For this purpose and this dataset, 
the standard basic descriptive statistics function, PROC MEANS, does not make sense to use in this data set 
because it has so many dimensions/properties, i.e., age, education level, sex.
Nor does a standard summary table of the counts by all variables, via PROC TABULATE, make sense. We are not interested in the 
ABSOLUTE counts, but rather the RELATIVE percentages of the various employment statuses. I.e., we are interested
in what PERCENTAGE are employed/unemployed in the various sex, age and education groups. 
For this purpose, the more relevant tables are those of relative frequencies. */

/* Analyze employment status distribution */
PROC FREQ DATA=aggregate_data;
    TABLES employment_status / NOCUM;
    WEIGHT count;
    TITLE 'Distribution of Employment Status';
RUN;

/* Create a stacked bar chart of employment status by age group */
PROC SGPLOT DATA=aggregate_data;
    VBAR age_group / GROUP=employment_status RESPONSE=count;
    TITLE 'Employment Status by Age Group';
RUN;

/* Create a cross-tabulation of employment status by age group*/
PROC FREQ DATA=aggregate_data;
    TABLES employment_status * age_group / NOCUM;
    WEIGHT count;
    TITLE 'Employment Status by Age Group';
RUN; 

/* Create a stacked bar chart of employment status by education level */
PROC SGPLOT DATA=aggregate_data;
    VBAR education_level / GROUP=employment_status RESPONSE=count;
    TITLE 'Employment Status by Education Level';
RUN;

/* Create a cross-tabulation of employment status and education level*/
PROC FREQ DATA=aggregate_data;
    TABLES employment_status * education_level / NOCUM;
    WEIGHT count;
    TITLE 'Employment status by Education Level';
RUN;

/* Create a stacked bar chart of employment status by sex */
PROC SGPLOT DATA=aggregate_data;
    VBAR sex / GROUP=employment_status RESPONSE=count;
    TITLE 'Employment Status by Sex';
RUN;

/* Create a cross-tabulation of employment status and sex*/
PROC FREQ DATA=aggregate_data;
    TABLES employment_status * sex / NOCUM;
    WEIGHT count;
    TITLE 'Employment status by Sex';
RUN;

/* Sort the data by age_group. SAS requires data to be sorted BEFORE using the BY statement. 
Sorting ensures that all age groups, including "67+", are properly ordered before the BY statement 
processes them in PROC SGPLOT.*/
PROC SORT DATA=aggregate_data;
    BY age_group;
RUN;

/* Create a stacked bar chart of employment status by education level and age group */
PROC SGPLOT DATA=aggregate_data;
    VBAR education_level / GROUP=employment_status RESPONSE=count GROUPORDER=DATA;
    BY age_group;
    TITLE 'Employment Status by Education Level and Age Group';
RUN;

/* Create a three-way cross-tabulation of employment status, education level, and age group */
PROC FREQ DATA=aggregate_data;
    TABLES employment_status * education_level * age_group / NOCUM;
    WEIGHT count;
    TITLE 'Employment Status by Education Level and Age Group';
RUN;

/* All of the stacked bar charts were basically visualizations of the percentages shown in the cross-tabulations. */

/* Close the PDF destination */
ODS PDF CLOSE;