LIBNAME proj "/home/u35920113/my_courses/Mk42/Marketing Analysis/Project"; 
filename House1 "/home/u35920113/my_courses/Mk42/Marketing Analysis/Project/kc_house_data.csv"; 
 
proc import datafile= House1 dbms=csv out=proj.house; 
run;

proc contents data=proj.house;
run;

/* Fetches missing values in specified columns */
proc means data=proj.house nmiss;
var grade bathrooms bedrooms condition price sqft_above sqft_basement sqft_living sqft_living15
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated;
run; 

/*** Convert date and zipcode ****/
data proj.house2;
set proj.house;
DATE1 = INPUT(PUT(date,8.),YYMMDD8.);
  FORMAT DATE1 YYMMDD8.;
yearpart=year(DATE1);
/*zip = input(zipcode, 8.);*/
run;

 /********* Training data *********/
proc surveyselect data=proj.house2 method=srs samprate=.7 out=train_data;
run;

/********** Validation Sample *********/
data proj.validation;
merge proj.house2(in=a) train_data(in=b);
if a and not b;
run;

proc contents data=proj.validation;
run;

/****Exploratory Analysis****/

/*** Is water front year 2014***//
proc sql;
create table iswaterfront as
select grade, bathrooms, bedrooms, condition, price, sqft_above, sqft_basement, sqft_living, sqft_living15, sqft_lot, sqft_lot15, view,
waterfront, yr_built, yr_renovated, zipcode from proj.house2
where waterfront = 1 and yearpart = 2014
order by date;
quit;
run;

/*** Is water front year 2015***//
proc sql;
create table iswaterfront_2015 as
select grade, bathrooms, bedrooms, condition, price, sqft_above, sqft_basement, sqft_living, sqft_living15, sqft_lot, sqft_lot15, view,
waterfront, yr_built, yr_renovated, zipcode from proj.house2
where waterfront = 1 and yearpart = 2015
order by date;
quit;
run;

/**** not water front ***/

proc sql;
create table notwaterfront as
select grade, bathrooms, bedrooms, condition, price, sqft_above, sqft_basement, sqft_living, sqft_living15, sqft_lot, sqft_lot15, view,
waterfront, yr_built, yr_renovated, zipcode from proj.house2
where waterfront = 0 and yearpart = 2014
order by zipcode;
quit;
run;
/**** not water front ***/

proc sql;
create table notwaterfront_2015 as
select grade, bathrooms, bedrooms, condition, price, sqft_above, sqft_basement, sqft_living, sqft_living15, sqft_lot, sqft_lot15, view,
waterfront, yr_built, yr_renovated, zipcode from proj.house2
where waterfront = 0 and yearpart = 2015
order by zipcode;
quit;

/**** Section1: Code to create a graph for average price and zipcode that can explain the high house value 
in specific zip codes (for presentation) **/
proc sql;
create table unique_zip as
select distinct(zipcode) as uniquezip,avg(price) as avgprice
from proj.house2
group by uniquezip;
quit;
run;

proc export data=unique_zip dbms=xls outfile='/home/u35920113/my_courses/Mk42/Marketing Analysis/Project/zip_data.xls' replace;
run;

ods graphics on;
proc gplot data=unique_zip;
plot avgprice * uniquezip;
run;
quit;

/**End of Section1*/

/*** Graphs ****/

ods graphics on;
proc gplot data=proj.house2;
plot price * bedrooms;
run;
quit;

ods graphics on;
proc gplot data=proj.house2;
plot price * bathrooms;
run;
quit;

ods graphics on;
proc gplot data=proj.house2;
plot price * sqft_living;
run;
quit;


proc sort data=proj.house2;
by descending yearpart;
run;

proc means data=proj.house2;
by descending yearpart ;
run;

/** price histogram for water front properties in 2014 ***/
proc univariate data = iswaterfront noprint;
histogram price;
run;

/**price vs sqft_living in water front properties **/
proc gplot data=iswaterfront;
plot price * sqft_living;
run;

/** price histogram for non water front properties in 2014 ***/
proc univariate data = notwaterfront noprint;
histogram price;
run;

/**price vs sqft_living in water front properties **/
proc gplot data=notwaterfront;
plot price * sqft_living;
run;

/**** Explanatory Analysis ****/

/*******Correlation********/
proc corr data=proj.house2;
run;

/****** Plain vanilla *******/


proc reg data=train_data;
model price= grade bathrooms bedrooms condition floors sqft_above sqft_basement sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated / Vif;
run;

/********* Standardized Estimates **********/

Proc reg data=proj.house2;
model price= grade bathrooms bedrooms condition floors sqft_above sqft_basement sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated / Selection=Stepwise stb;
run;



/****** Factor Analysis *****///

proc factor data=proj.house2 method=prin scree;
var grade bathrooms bedrooms condition sqft_above sqft_basement sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated;
run;

proc factor data=proj.house2 method=prin scree rotate=varimax;
var grade bathrooms bedrooms condition sqft_above sqft_basement sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated ;
run;

proc factor data=proj.house2 method=prin scree n=5 out=house_factors; 
var grade bathrooms bedrooms condition sqft_above sqft_basement sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated ;
run;

/** PCA **/

proc princomp data=proj.house2 out=components;
var grade bathrooms bedrooms condition sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated;
run;



/**** Cluster Analysis ***/


proc cluster data=proj.house2 outtree= components_tree noeigen method=centroid print=10;
/*var factor1 factor2 factor3 factor4 factor5;*/
var grade bathrooms bedrooms condition sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated;
run;

/* Takes around 3 mins to run on the entire dataset */
ods graphics on;
proc tree data= components_tree out=out2 nclusters=3; /**noprint nclusters=4 out=out;**/
copy grade bathrooms bedrooms condition sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated;

run;
ods graphics off;

/** end of old cluster code **//

/* k-means clustering */
proc fastclus data=components maxclusters=3 maxiter=20 out=out_fastclus list;
var grade bathrooms bedrooms condition sqft_living sqft_living15 
sqft_lot sqft_lot15 view waterfront yr_built yr_renovated zipcode;
run;

proc contents data=out_fastclus;
run;

proc sgplot data=out_fastclus;
scatter y=sqft_living x=grade / group=cluster;
run;

proc sgplot data=out_fastclus;
scatter y=sqft_living x=zipcode / group=cluster;
run;
proc sgplot data=out_fastclus;
scatter y=zipcode x=grade / group=cluster;
run;


/******* Model-1 *******/
PROC REG DATA=train_data;
model price=bedrooms bathrooms sqft_living sqft_lot waterfront view condition grade
sqft_above sqft_basement yr_built yr_renovated lat long sqft_living15 sqft_lot15 ;
RUN;

PROC REG DATA=train_data;
model price=bedrooms bathrooms sqft_living sqft_lot waterfront view condition grade
sqft_above sqft_basement yr_built yr_renovated lat long sqft_living15 sqft_lot15 / STB;
RUN;




/********** Model-2 ********/
DATA housedata2;
SET proj.house2;
sqft_living_Sq=sqft_living*sqft_living;
sqft_basement_Sq=sqft_basement*sqft_basement;
RUN;


PROC REG DATA=housedata2;
model price=bedrooms bathrooms sqft_living_Sq sqft_lot waterfront view condition grade
sqft_above sqft_basement_Sq yr_built yr_renovated lat long sqft_living15 sqft_lot15 ;
RUN;

/********** Model-3 ********/


DATA housedata3;
SET proj.house2;
sqft_living_Sq=sqft_living*sqft_living;
sqft_basement_Sq=sqft_basement*sqft_basement;
sqft_living_Log=Log(sqft_living);
sqft_living_Cu=sqft_living*sqft_living*sqft_living;
bedrooms_Sq=bedrooms*bedrooms;
bathrooms_Sq=bathrooms*bathrooms;
sqft_lot_Sq=sqft_lot*sqft_lot;
sqft_living15_Sq=sqft_living15*sqft_living15;
sqft_lot15_Sq=sqft_lot15*sqft_lot15;
RUN;

PROC REG DATA=housedata3;
model price=bedrooms bathrooms sqft_living_Sq sqft_lot_Sq waterfront view condition grade
sqft_above sqft_basement_Sq sqft_living_Log sqft_living_Cu yr_built yr_renovated lat long sqft_living15_Sq
sqft_lot15_Sq ;
RUN;