/* Set up destination pdf file for saving all SAS results. 
The Listing style keeps formatting exactly as printed in SAS. */
ODS PDF FILE='/home/u64257150/EmploymentStatus/1)Preprocessing/preprocessingresults.pdf' STYLE=LISTING;

/* I opened the raw unprocessed csv data from Statistikbanken in Excel, choosing the Nordic characters,
because SAS couldn't recognize the Danish characters. This is why my code has odd characters in the
place of Danish ones. I then added a first row of variable names to this raw csv file. These are the
only changes made before importing into SAS.*/
proc import datafile='/home/u64257150/EmploymentStatus/0)Data/raw_data.csv'
    out=unprocessed_data
    dbms=csv
    replace;
    getnames=yes;
run;

/* Simplifying data by truncating sex, education level and collapsing some variables
into fewer groups*/
data collapsed_data;
    set unprocessed_data;
    
    /* Truncate sex to the first 1 character, then transform into dummy variable. */
    sex = SUBSTR(sex, 1, 1);
    select (sex);
    	when ('M') sex = 1;
    	when ('K') sex = 0;
        OTHERWISE 
            sex = 'Unknown';
    END;
        
    /* Collapse age groups into fewer */
    SELECT (age_group);
        /* Group 1: 16-29 */
        WHEN ('16-19 σr', '20-24 σr', '25-29 σr') 
            age_group = '16-29';
        
        /* Group 2: 30-49 */
        WHEN ('30-34 σr', '35-39 σr', '40-44 σr', '45-49 σr') 
            age_group = '30-49';
        
        /* Group 3: 50-66 */
        WHEN ('50-54 σr', '55-59 σr', '60-64 σr', '65-66 σr') 
            age_group = '50-66';
        
        /* Group 4: 67+ */
        WHEN ('67 σr og') 
            age_group = '67+';
        
        OTHERWISE 
            age_group = 'Unknown';
    END;
    
    /* Truncate education_level values to the first 3 characters */
    education_level = SUBSTR(education_level, 1, 3);
    
    /* Collapse education levels H20-35 and H50-60 into single groups, since H20-35 include
    all gymnasie-level educations, be they erhvervs- or akademisk-rettet. H50-60 are all
    bachelors, be they professions- or akademiske. */
    SELECT (education_level);
        WHEN ('H20', 'H30', 'H35') education_level = 'H20_35';
        WHEN ('H50', 'H60') education_level = 'H50_60';
        OTHERWISE; /* Keep other values as is */
    END;
    
    /* Collapse employment statuses into fewer groups */
    select (employment_status);
        /* Employed group */
        when ('Selvstµndige', 'Medarbejdende µgtefµller', 
              'L°nmodtager med ledelsesarbejde', 
              'L°nmodtagere pσ h°jeste niveau',
              'L°nmodtagere pσ mellemniveau',
              'L°nmodtagere pσ grundniveau',
              'Andre l°nmodtagere',
              'L°nmodtagere u.n.a.') 
            employment_status = 'Employed';
            
        /* Unemployed/Leave group */
        when ('Arbejdsl°se', 'St°ttet beskµftigelse uden l°n',
              'Vejledning og opkvalificering', 'Ledighedsydelse',
              'Kontanthjµlp (passiv)/integrationsydelse', 'Revalidering',
              'Ressourceforl°b', 'Jobafklaringsforl°b',
              'Feriedagpenge', 'B°rnepasningsorlov fra ledighed',
              'Barselsfravµr fra ledighed', 'Sygefravµr fra ledighed')
            employment_status = 'Unemployed';
            
        /* Education/Training group */
        when ('Personer under uddannelse (ordinµr)', 'Kursister',
              'Produktionsskoleelever', 'Udenlandske studerende',
              'SU-modtagere')
            employment_status = 'In Education or Training';
            
        /* Retirement/Pension group */
        when ('F°rtidspension', 'Seniopension', 'Tidlig pension',
              'Efterl°n', 'Fleksydelse', 'Folkepension',
              'Anden pension')
            employment_status = 'On Pension';
            
        /* Other group */
        when ('╪vrige uden for arbejdsstyrken')
            employment_status = 'Not in Labor Force';
            
        otherwise employment_status = 'Unknown';
    end;
RUN;

/* The original raw dataset has now been simplified through truncating and collapsing. But it is still 
COUNT data, that is, aggregate data. I will export this processed aggregate data to a separate csv file, to
carry out aggregate analysis on it in a separate script. */
PROC EXPORT DATA=collapsed_data
    OUTFILE='/home/u64257150/EmploymentStatus/1)Preprocessing/aggregate_data.csv'
    DBMS=CSV
    REPLACE;
RUN; 

/* But I also want to carry out individual-level data analysis. That is, I need to create observations for each
and every individual in the counts (with all other properties for that row staying the same). So I will 
expand it to individual-level data.*/
data individual_data;
    set collapsed_data;
    do i = 1 to Count;
        output;
    end;
    drop Count i;
run; 

/* Check that the number of rows in this transformed individual-level dataset equals the total sum 
of counts, ie the total number of individuals included, in the aggregate (collapsed) dataset. 
Store counts in macro variables and compare */
PROC SQL;
    SELECT SUM(count) INTO :count_sum
    FROM collapsed_data;
    
    SELECT COUNT(*) INTO :row_count
    FROM individual_data;
QUIT;

/* Compare the values */
/* Create a dataset with the comparison results */
DATA comparison_results;
    length result $200;
    count_sum = &count_sum;
    row_count = &row_count;
    
    IF count_sum = row_count THEN
        result = "Counts are equal.";
    ELSE
        result = "Counts are different.";
    OUTPUT;
RUN;

/* Print the results, which ended up showing that the counts are equal. */
PROC PRINT DATA=comparison_results;
    VAR result;
    TITLE 'Comparison of Dataset Counts';
RUN;

/* Export the full individual-level dataset */
PROC EXPORT DATA=individual_data
    OUTFILE='/home/u64257150/EmploymentStatus/1)Preprocessing/individual_data.csv'
    DBMS=CSV
    REPLACE;
RUN;

/* Close the PDF destination */
ODS PDF CLOSE;