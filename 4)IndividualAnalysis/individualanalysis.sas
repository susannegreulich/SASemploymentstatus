/* THIS SCRIPT IS A WORK IN-PROGRESS. I have yet to think about the proper ways to set up the discrete
multivariate analysis and regressions, and how to interpret the results. */

/* Set up destination pdf file for saving all SAS results. 
The Listing style keeps formatting exactly as printed in SAS. */
ODS PDF FILE='/home/u64257150/EmploymentStatus/4)IndividualAnalysis/individualanalysisresults.pdf' STYLE=LISTING;

/* Import individual-level data SAMPLE, with appropriate lengths and formats.*/
DATA individual_data;
    INFILE '/home/u64257150/EmploymentStatus/2)Sampling/stratified_individual_sample.csv' DLM=',' FIRSTOBS=2;
    INPUT sex :1. age_group :$10. education_level :$10. employment_status :$25.;
RUN;

/* =====================================================
   ANALYSIS 1: INDIVIDUAL-LEVEL LOGISTIC REGRESSION
   Advantage: Can model individual probability of outcomes
   Aggregate limitation: Can only model group-level probabilities
   ===================================================== */

/* Create binary outcome variables for different employment statuses */
DATA individual_data;
    SET individual_data;
    /* Binary indicators for each employment status */
    employed = (employment_status = 'Employed');
    unemployed = (employment_status = 'Unemployed');
    in_education = (employment_status = 'In Education or Training');
    on_pension = (employment_status = 'On Pension');
    not_labor_force = (employment_status = 'Not in Labor Force');
    
    /* Create interaction terms (individual-level advantage) */
    male_high_edu = sex * (education_level IN ('H40', 'H50_60', 'H70', 'H80', 'H90'));
    young_male = sex * (age_group = '16-29');
    female_high_edu = (1 - sex) * (education_level IN ('H40', 'H50_60', 'H70', 'H80', 'H90'));
RUN;

/* Individual-level logistic regression with interactions */
PROC LOGISTIC DATA=individual_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employed = sex education_level age_group male_high_edu young_male;
    OUTPUT OUT=logistic_results PRED=pred_prob PREDPROBS=CROSSVALIDATE;
    TITLE 'Individual-Level Logistic Regression: Employment Probability';
    TITLE2 'With Interaction Terms (Individual-Level Advantage)';
RUN;

/* =====================================================
   ANALYSIS 2: MULTINOMIAL LOGISTIC REGRESSION
   Advantage: Can model all employment statuses simultaneously
   Aggregate limitation: Difficult to model multiple outcomes together
   ===================================================== */

PROC LOGISTIC DATA=individual_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employment_status(ref='Not in Labor Force') = sex education_level age_group / LINK=GLOGIT;
    OUTPUT OUT=multinomial_results PRED=pred_prob;
    TITLE 'Multinomial Logistic Regression: All Employment Statuses';
    TITLE2 'Individual-Level Advantage: Modeling Multiple Outcomes';
RUN;

/* =====================================================
   ANALYSIS 3: INDIVIDUAL-LEVEL PREDICTIVE MODELING
   Advantage: Can predict individual outcomes and assess model fit
   Aggregate limitation: Cannot predict individual behavior
   ===================================================== */

/* Split data for training and validation (individual-level advantage) */
PROC SURVEYSELECT DATA=individual_data OUT=training_data 
    METHOD=SRS SAMPRATE=0.7 SEED=12345;
RUN;

DATA validation_data;
    SET individual_data;
    IF _N_ > 0.7 * N THEN OUTPUT;
RUN;

/* Train model on training data */
PROC LOGISTIC DATA=training_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employed = sex education_level age_group;
    SCORE OUT=scored_training;
    TITLE 'Training Model on Individual-Level Data';
RUN;

/* Validate on holdout sample */
PROC LOGISTIC DATA=validation_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employed = sex education_level age_group;
    SCORE OUT=scored_validation;
    TITLE 'Validation on Individual-Level Holdout Sample';
RUN;

/* =====================================================
   ANALYSIS 4: INDIVIDUAL-LEVEL HETEROGENEITY ANALYSIS
   Advantage: Can identify individual-level variation and outliers
   Aggregate limitation: Cannot see individual variation within groups
   ===================================================== */

/* Calculate individual-level residuals and identify outliers */
PROC LOGISTIC DATA=individual_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employed = sex education_level age_group;
    OUTPUT OUT=residual_analysis RESCHI=pearson_residual PRED=pred_prob;
RUN;

/* Identify individuals with unusual patterns */
DATA outlier_analysis;
    SET residual_analysis;
    IF ABS(pearson_residual) > 2 THEN outlier_flag = 1;
    ELSE outlier_flag = 0;
    
    /* Calculate individual-level surprise (unexpected outcomes) */
    surprise = ABS(employed - pred_prob);
    high_surprise = (surprise > 0.3);
RUN;

PROC FREQ DATA=outlier_analysis;
    TABLES outlier_flag*sex / CHISQ;
    TITLE 'Individual-Level Outlier Analysis';
    TITLE2 'Identifying Unusual Individual Patterns';
RUN;

/* =====================================================
   ANALYSIS 5: INDIVIDUAL-LEVEL SEGMENTATION
   Advantage: Can create individual-level segments and profiles
   Aggregate limitation: Can only segment at group level
   ===================================================== */

/* Create individual-level risk scores */
DATA individual_segments;
    SET individual_data;
    
    /* Individual-level risk scoring */
    risk_score = 0;
    IF sex = 1 THEN risk_score = risk_score + 1; /* Male */
    IF education_level IN ('H10', 'H20_35') THEN risk_score = risk_score + 2;
    IF age_group = '16-29' THEN risk_score = risk_score + 1;
    
    /* Create individual segments based on risk */
    IF risk_score <= 2 THEN segment = 'Low Risk';
    ELSE IF risk_score <= 4 THEN segment = 'Medium Risk';
    ELSE segment = 'High Risk';
    
    /* Individual-level employment probability */
    IF employed = 1 THEN actual_employed = 1;
    ELSE actual_employed = 0;
RUN;

PROC MEANS DATA=individual_segments;
    CLASS segment;
    VAR actual_employed;
    TITLE 'Individual-Level Risk Segmentation';
    TITLE2 'Employment Rates by Individual Risk Segments';
RUN;

/* =====================================================
   ANALYSIS 6: INDIVIDUAL-LEVEL MARGINAL EFFECTS
   Advantage: Can calculate individual-specific marginal effects
   Aggregate limitation: Can only calculate group-level effects
   ===================================================== */

/* Calculate individual-level marginal effects */
PROC LOGISTIC DATA=individual_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employed = sex education_level age_group;
    OUTPUT OUT=marginal_effects PRED=pred_prob;
RUN;

DATA individual_marginal_effects;
    SET marginal_effects;
    
    /* Individual-level marginal effects (approximation) */
    /* For each individual, how much does being male affect their employment probability? */
    male_effect = pred_prob * (1 - pred_prob) * 0.5; /* Simplified marginal effect */
    
    /* Individual-specific education premium */
    IF education_level IN ('H40', 'H50_60', 'H70', 'H80', 'H90') THEN edu_premium = pred_prob * 0.3;
    ELSE edu_premium = 0;
RUN;

PROC MEANS DATA=individual_marginal_effects;
    CLASS education_level;
    VAR male_effect edu_premium;
    TITLE 'Individual-Level Marginal Effects';
    TITLE2 'How Variables Affect Each Individual Differently';
RUN;

/* =====================================================
   ANALYSIS 7: INDIVIDUAL-LEVEL SIMULATION
   Advantage: Can simulate individual outcomes under different scenarios
   Aggregate limitation: Can only simulate group-level outcomes
   ===================================================== */

/* Simulate what would happen if all individuals had higher education */
DATA simulation_scenario;
    SET individual_data;
    
    /* Original employment status */
    original_employed = employed;
    
    /* Simulate scenario: What if everyone had H40+ education? */
    IF education_level IN ('H10', 'H20_35') THEN DO;
        /* Increase employment probability for lower education groups */
        simulated_employed = (employed = 1 OR (RANUNI(12345) < 0.2));
    END;
    ELSE simulated_employed = employed;
RUN;

PROC MEANS DATA=simulation_scenario;
    CLASS education_level;
    VAR original_employed simulated_employed;
    TITLE 'Individual-Level Policy Simulation';
    TITLE2 'Simulating Education Policy Impact on Individual Employment';
RUN;

/* =====================================================
   ANALYSIS 8: INDIVIDUAL-LEVEL CONFIDENCE INTERVALS
   Advantage: Can calculate individual-specific uncertainty
   Aggregate limitation: Can only calculate group-level confidence intervals
   ===================================================== */

PROC LOGISTIC DATA=individual_data;
    CLASS education_level(ref='H10') age_group(ref='16-29');
    MODEL employed = sex education_level age_group;
    OUTPUT OUT=confidence_intervals PRED=pred_prob PREDPROBS=INDIVIDUAL;
    TITLE 'Individual-Level Prediction Intervals';
    TITLE2 'Uncertainty for Each Individual Prediction';
RUN;

/* =====================================================
   ANALYSIS 9: INDIVIDUAL-LEVEL MACHINE LEARNING APPROACHES
   Advantage: Can use individual-level data for advanced ML techniques
   Aggregate limitation: Cannot apply ML to group-level data
   ===================================================== */

/* Individual-level decision tree approach using PROC HPSPLIT */
PROC HPSPLIT DATA=individual_data;
    CLASS education_level age_group;
    MODEL employed = sex education_level age_group;
    PRUNE NONE;
    TITLE 'Individual-Level Decision Tree';
    TITLE2 'Machine Learning Approach to Individual Prediction';
RUN;

/* =====================================================
   ANALYSIS 10: INDIVIDUAL-LEVEL LONGITUDINAL SIMULATION
   Advantage: Can simulate individual life courses and transitions
   Aggregate limitation: Cannot model individual transitions
   ===================================================== */

/* Simulate individual transitions between employment states */
DATA life_course_simulation;
    SET individual_data;
    
    /* Individual-level transition probabilities */
    IF age_group = '16-29' THEN DO;
        /* Young individuals more likely to transition */
        transition_prob = 0.3;
    END;
    ELSE IF age_group = '30-49' THEN DO;
        transition_prob = 0.2;
    END;
    ELSE transition_prob = 0.1;
    
    /* Simulate next period employment status */
    IF RANUNI(12345) < transition_prob THEN DO;
        /* Transition to different state */
        IF employed = 1 THEN next_period_employed = 0;
        ELSE next_period_employed = 1;
    END;
    ELSE next_period_employed = employed;
RUN;

PROC FREQ DATA=life_course_simulation;
    TABLES employed*next_period_employed / CHISQ;
    TITLE 'Individual-Level Transition Analysis';
    TITLE2 'Simulating Individual Employment Transitions';
RUN;

/* Export key individual-level results */
PROC EXPORT DATA=individual_segments
    OUTFILE='/home/u64257150/EmploymentStatus/4)IndividualAnalysis/individual_segments.csv'
    DBMS=CSV
    REPLACE;
RUN;

PROC EXPORT DATA=outlier_analysis
    OUTFILE='/home/u64257150/EmploymentStatus/4)IndividualAnalysis/individual_outliers.csv'
    DBMS=CSV
    REPLACE;
RUN;

TITLE;
FOOTNOTE; 

/* Close the PDF destination */
ODS PDF CLOSE;