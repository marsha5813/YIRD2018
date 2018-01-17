
* Read in data
clear all
import delim county-level-data.csv

* Data wrangling
gen pct_anger_words = (numanger/numwords)*100
gen pct_fear_words = (numfear/numwords)*100
gen pct_anticipation_words = (numanticipation/numwords)*100
gen pct_trust_words = (numtrust/numwords)*100
gen pct_surprise_words = (numsurprise/numwords)*100
gen pct_sadness_words = (numsadness/numwords)*100
gen pct_joy_words = (numjoy/numwords)*100
gen pct_disgust_words = (numdisgust/numwords)*100
gen pct_neg_words = (numneg/numwords)*100
gen pct_pos_words = (numpos/numwords)*100

label var pct_anger_words "Percent angry words of all words in county, dict classified"
label var pct_fear_words "Percent fear words of all words in county, dict classified"
label var pct_anticipation_words "Percent anticipation words of all words in county, dict classified"
label var pct_trust_words "Percent trust words of all words in county, dict classified"
label var pct_surprise_words "Percent surprise words of all words in county, dict classified"
label var pct_sadness_words "Percent sadness words of all words in county, dict classified"
label var pct_joy_words "Percent joy words of all words in county, dict classified"
label var pct_neg_words "Percent neg words of all words in county, dict classified"
label var pct_disgust_words "Percent disgust words of all words in county, dict classified"
label var pct_pos_words "Percent pos words of all words in county, dict classified"

gen fips_str = string(fips)
gen str zero = "0"
replace fips_str = zero + fips_str if fips<10000
drop zero
rename fips fips_numeric
rename fips_str fips

foreach var of varlist pct* {
	cap drop ln_`var'
	gen ln_`var' = ln(`var'+1)
}

* Merge in RCMS data
merge 1:1 fips using "U.S. Religion Census Religious Congregations and Membership Study, 2010 (County File).dta", nogen

* Merge in county controls
merge 1:1 fips using countydata2, nogen
drop if v1==.
rename b79aa_2010 median_income
gen propmale2010 = a08aa_2010/POP2010
gen crimerate2000 = crime_ucr_modindex_2000/POP2010
gen pblack2010 = b08ab_2010/POP2010
gen pforeign2010 = at5ab_2010/POP2010
gen pwhite2010 = b08aa_2010/POP2010

* Merge in voting data
merge 1:1 fips using county-2016-election-data.dta, nogen
recode election16 (2=0), gen(gop16)
label var gop16 "County voted republican in 2016 pres election"

* Census division versus region
rename region_2010 division_2010
recode division_2010 (1 2 = 1) (3 4 = 2) (5 6 7 = 3) (8 9 = 4), gen(region_2010)
label def division 1 "Northeast" 2 "Midwest" 3 "South" 4 "West"
label values region_2010 division
tab region_2010

* percentiles of predictors
label def quintiles 1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5"
foreach i of global predictors {
	cap drop `i'_5tile
	xtile `i'_5tile = `i' if numtweets>=30, n(5)
	label var `i'_5tile "Quintiles of `i', counties with >=30 tweets"
	label values `i'_5tile quintiles
	cap drop `i'_10tile
	xtile `i'_10tile = `i' if numtweets>=30, n(10)
	label var `i'_10tile "Deciles of `i', counties with >=30 tweets"
}


* Categorize counties as high or low adherence rate
label def ptilecats 1 "Adherence rate at or below 1st decile" 2 "Adherence rate at or above 10th decile"
foreach i of global predictors {
	cap drop `i'_cat
	gen `i'_cat = . 
	replace `i'_cat = 1 if `i'_10tile==1
	replace `i'_cat = 2 if `i'_10tile==10
	label values `i'_cat ptilecats
}


* Save data
save workdata,replace



***************** Analysis

* Assign variables to lists
global dvs "pct_pos_words pct_anger_words pct_fear_words pct_sadness_words pct_joy_words pct_disgust_words pct_neg_words pct_pos_words"
global predictors "totrate evanrate mprtrate bprtrate cathrate"
global controls "median_income propmale2010 crimerate2000 pblack2010 pforeign2010 pwhite2010 i.gop16 i.region_2010 gini_rpme_2010"
global controls2 "median_income propmale2010 crimerate2000 pblack2010 pforeign2010 gini_rpme_2010 POP2010 i.gop16 i.region_2010"
global options "if useit"
global dv1 "pct_neg_words"



* Figure 1
* I just generated and pasted the values into Excel and then loaded them into Tableau.
* Could devise a more efficient computational way to make the data vizzes.
foreach i of global predictors {
	di "********** ANGER ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_anger_words)
	ttest pct_anger_words, by(`i'_cat)
	
	di "********** DISGUST ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_disgust_words)
	ttest pct_disgust_words, by(`i'_cat)
	
	di "********** FEAR ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_fear_words)
	ttest pct_fear_words, by(`i'_cat)
	
	di "********** JOY ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_joy_words)
	ttest pct_joy_words, by(`i'_cat)
	
	di "********** SADNESS ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_sadness_words)
	ttest pct_sadness_words, by(`i'_cat)
	
	di "********** NEGATIVE ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_neg_words)
	ttest pct_neg_words, by(`i'_cat)
	
	di "********** POSITIVE ***********"
	tab `i'_10tile if `i'_10tile==1 | `i'_10tile==10, sum(pct_pos_words)
	ttest pct_pos_words, by(`i'_cat)

}




* Table 2
reg $dvs $predictors $controls if numtweets>=30
cap drop useit
gen useit = e(sample) // to get number of cases for models

reg $dv1 totrate $controls2 $options
est store m1
reg $dv1 evanrate $controls2 $options
est store m2
reg $dv1 mprtrate $controls2 $options
est store m3
reg $dv1 bprtrate $controls2 $options
est store m4
reg $dv1 cathrate $controls2 $options
est store m5

quietly esttab m1 m2 m3 m4 m5 using table2.html, replace t nogaps beta r2 order($predictors) nobase nonum wide compress ///
mti("M1" "M2" "M3" "M4" "M5") ///
coeflabels(evanrate "Evangelical adherence rate" ///
mprtrate "Mainline adherence rate" ///
bprtrate "Black Prot. adherence rate" ///
cathrate "Catholic adherence rate" ///
totrate "Total adherence rate" ///
median_income "Median income" ///
propmale2010 "Percent male" ///
crimerate2000 "Crime rate" ///
pblack2010 "Percent black" ///
pforeign2010 "Percent foreign born" ///
1.gop16 "County voted GOP in 2016" ///
gini_rpme_2010 "County Gini coefficient" ///
1.region_2010 ".....Northeast (ref)" ///
2.region_2010 ".....Midwest" ///
3.region_2010 ".....South" ///
4.region_2010 ".....West") ///
refcat(2.region_2010 "<br> <strong>Region (ref=Northeast)</strong>" median_income "<br> <strong>Controls</strong>", nolabel)






**************** Extra stuff

* comparison of different models
tobit ln_pct_pos_words totrate if numtweets>30, ll(0) //tobit

ssc install tpm
tpm ln_pct_pos_words totrate, first(logit) second(regress) //two-part


* histograms
foreach var of varlist pct* {
	hist `var', ti("`var'")
	graph save `var', replace
	hist ln_`var', ti("ln_`var'")
	graph save ln_`var', replace
}
graph combine pct_anger_words.gph pct_fear_words.gph pct_anticipation_words.gph ///
	pct_trust_words.gph pct_surprise_words.gph pct_sadness_words.gph ///
	pct_joy_words.gph pct_neg_words.gph pct_disgust_words.gph pct_pos_words.gph
graph export histograms.png, replace

graph combine ln_pct_anger_words.gph ln_pct_fear_words.gph ln_pct_anticipation_words.gph ///
	ln_pct_trust_words.gph ln_pct_surprise_words.gph ln_pct_sadness_words.gph ///
	ln_pct_joy_words.gph ln_pct_neg_words.gph ln_pct_disgust_words.gph ln_pct_pos_words.gph
graph export histograms_logged.png, replace

! del *.gph




* export to excel for tableau purposes
export excel fips *pct* totrate evanrate bprtrate mprtrate cathrate *10tile high* low* ///
median_income propmale2010 crimerate2000 pblack2010 pforeign2010 pwhite2010 gop16 region_2010 ///
numtweets ///
using "workdata.xlsx" , firstrow(variables) replace

















