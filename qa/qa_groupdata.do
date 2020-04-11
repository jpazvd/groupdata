*-----------------------------------------------------------------------------
*	Title: 	Groupdata QA
*	Data:	April 6th 2020
* 	Author: Joao Pedro Azevedo
*-----------------------------------------------------------------------------
*
*	Povcalnet Calculator
*
*	http://iresearch.worldbank.org/PovcalNet/PovCalculator.aspx
*
*-----------------------------------------------------------------------------
* Globals

cap whereis github
if _rc == 0 global clone "`r(github)'/LearningPoverty-Brazil"

cap whereis myados
if _rc == 0 global myados "`r(myados)'"

global output "${myados}/groupdata/qa/"

*-----------------------------------------------------------------------------
* Prepare test data

cd "${myados}\groupdata\src"
discard

*use "${clone}\02_rawdata\INEP_SAEB\SAEB_ALUNO_COVID.dta", clear

*-----------------------------------------------------------------------------
* Prepare test data

foreach yr in 2011 2013 2015 2017 {
    use "${github}\LearningPoverty-Brazil\02_rawdata\INEP_SAEB\Downloads\SAEB_ALUNO_`yr'.dta", clear
	sample 10 
	save "$output\score`yr'", replace
}

*-----------------------------------------------------------------------------
*	Learning Distribution - 5th Grade
*-----------------------------------------------------------------------------

clear
forvalues year=2011(2)2017 {
  append using "${clone}/02_rawdata/INEP_SAEB/Downloads/SAEB_ALUNO_`year'.dta"
}
keep if in_situacao_censo == 1 & idgrade==5
keep year id* private* score_lp learner_weight_lp

sample 10 , by(year)

graph twoway		///
	(kdensity score_lp [aw=learner_weight_lp] if year==2011) 	///
	(kdensity score_lp [aw=learner_weight_lp] if year==2013) 	///
	(kdensity score_lp [aw=learner_weight_lp] if year==2015) 	///
	(kdensity score_lp [aw=learner_weight_lp] if year==2017), 	///
			xline(200) ///
			legend(label(1 "2011") label(2 "2013") label(3 "2015") label(4 "2017"))
	
*-----------------------------------------------------------------------------
*	Learning Distribution - 9th Grade
*-----------------------------------------------------------------------------

clear
forvalues year=2011(2)2017 {
  append using "${clone}/02_rawdata/INEP_SAEB/Downloads/SAEB_ALUNO_`year'.dta"
}
keep if in_situacao_censo == 1 & idgrade==9
keep year id* private* score_lp learner_weight_lp

sample 10 , by(year)

graph twoway		///
	(kdensity score_lp [aw=learner_weight_lp] if year==2011) ///
	(kdensity score_lp [aw=learner_weight_lp] if year==2013) ///
	(kdensity score_lp [aw=learner_weight_lp] if year==2015) ///
	(kdensity score_lp [aw=learner_weight_lp] if year==2017), 	///
			xline(200) ///
			legend(label(1 "2011") label(2 "2013") label(3 "2015") label(4 "2017"))


			
*-----------------------------------------------------------------------------
* Learning Poverty Simulation (distributionally neutral) - generate group data

use "$output\score2017", clear

* check group data estiamtes from unit records 

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group 

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure 

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure bins(15)

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure bins(15)

* generated groupped data for check from group data to group data estimates
alorenz score_lp [aw=learner_weight_lp] if idgrade == 5, fullview points(15)
mat a = r(lorenz1) 
svmat double a, names(col)
						

* mean  (Type 1: OK) accepts only AW
groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200) mu(214.28) type(1) nofigure nochecks noelasticities
						
* mean  (Type 2: OK) accepts only AW
groupdata prop_score_lp 	[aw=prop_pop ] 		, z(200) mu(214.28) type(2) nofigure nochecks noelasticities
						
* mean  (Type 5: Fail) noweight
groupdata mean_score_lp 						, z(200) mu(214.28) type(5) nofigure nochecks noelasticities

* mean  (Type 5: OK) pw
groupdata mean_score_lp 	[pw=prop_pop]		, z(200) mu(214.28) type(5) nofigure nochecks noelasticities


* max 	(Type 6: OK)

tabstat score_lp [aw= learner_weight_lp ] , by(idgrade) stat(mean min max)

groupdata maxscore_lp	 						, z(200) mu(214.28) type(5) nofigure nochecks noelasticities
groupdata maxscore_lp	 						, z(200) mu(214.28) type(6) nofigure nochecks noelasticities min(92.0619) max(334.22818)




*******************************************************
* mean  (Type 1: OK) accepts only AW
groupdata ac_prop_score_lp [aw=ac_prop_pop] , z(200) mu(214.28) nofigure type(1) nochecks noelasticities nolorenz
						
*******************************************************
* mean  (Type 2: OK) accepts only AW
groupdata prop_score_lp [aw=prop_pop ] , z(200) mu(214.28) nofigure type(2) nochecks noelasticities
						
*******************************************************
* mean  (Type 5: OK) noweight; pw; fw
groupdata mean_score_lp , z(200) mu(214.28) nofigure type(5) nochecks noelasticities nolorenz

*******************************************************
* max 	(Type 6: OK)
groupdata maxscore_lp , z(200) mu(214.28) nofigure type(6) nochecks noelasticities min(92.0619) max(334.22818) nolorenz





graph twoway		///
	(kdensity mean_score_lp ) ///
	(kdensity maxscore_lp1) 
			
			
* Lorenz			
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) benchmark group nofigure
			
*-----------------------------------------------------------------------------
* Learning Poverty Simulation (distributionally neutral)

use "$output\score2017", clear
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) bins(10) benchmark group regress nofig
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) bins(15) mu(207.9) benchmark group 


use "$output\score2015", clear
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(214.8) group 
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(207.9) group 


use "$output\score2013", clear
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(214.8) group 
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(207.9) group 


use "$output\score2011", clear
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group bins(10) benchmark
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(214.8) group 
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(207.9) group 
  
*-----------------------------------------------------------------------------
* Distributional Impact  
  
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5 & year == 2017, ///
			z(200) bins(15) group nofig noe noch
  
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5 & year == 2017, ///
			z(200) bins(15) mu(210.9) group nofig noe noch

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5 & year == 2015, ///
			z(200) bins(15) mu(210.9) group nofig noe noch

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5 & year == 2011, ///
			z(200) bins(15) mu(210.9) group nofig noe noch


graph twoway		///
	(kdensity score_lp [aw=learner_weight_lp] if year==2011) ///
	(kdensity score_lp [aw=learner_weight_lp] if year==2015) ///
	(kdensity score_lp [aw=learner_weight_lp] if year==2017), 	///
			xline(200) ///
			legend(label(1 "2011") label(2 "2015") label(3 "2017") cols(3)) ///
			xtitle("reading score (SAEB, 5th Grade)")
  
*-----------------------------------------------------------------------------
/*

Type 1 grouped data: P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population

Type 2 grouped data: Q=Proportion of population, R=Proportion of incometype 

5 grouped data: W=Percentage of the population in a given interval of incomes, X=The mean income of that interval.

Unit record data: Percentage of the population with same income level, The income level.

*/

use "$output\score2017", clear

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) benchmark group 

/*
. groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) benchmark group  regress

Estimation using grouped data...

... creating groupped data with 20 bins.



Estimation: GQ Lorenz Curve (grouped data)

      Source |       SS           df       MS      Number of obs   =        19
-------------+----------------------------------   F(3, 16)        >  99999.00
       Model |  .639812787         3  .213270929   Prob > F        =    0.0000
    Residual |  3.4693e-07        16  2.1683e-08   R-squared       =    1.0000
-------------+----------------------------------   Adj R-squared   =    1.0000
       Total |  .639813134        19  .033674375   Root MSE        =    .00015

------------------------------------------------------------------------------
          yg |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
          ag |   1.148072   .0050039   229.44   0.000     1.137464     1.15868
          bg |   -1.99792   .0023046  -866.92   0.000    -2.002805   -1.993034
          cg |   .1464733   .0070504    20.78   0.000     .1315272    .1614194
------------------------------------------------------------------------------


Estimation: Beta Lorenz Curve (Grouped data)

      Source |       SS           df       MS      Number of obs   =        19
-------------+----------------------------------   F(2, 16)        =  25297.85
       Model |   3.7637007         2  1.88185035   Prob > F        =    0.0000
    Residual |  .001190204        16  .000074388   R-squared       =    0.9997
-------------+----------------------------------   Adj R-squared   =    0.9996
       Total |   3.7648909        18  .209160606   Root MSE        =    .00862

------------------------------------------------------------------------------
         yg2 |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
         x1g |   .8673738    .004058   213.75   0.000     .8587713    .8759763
         x2g |   .8566519    .004058   211.10   0.000     .8480493    .8652545
       _cons |  -1.142125   .0073633  -155.11   0.000    -1.157735   -1.126516
------------------------------------------------------------------------------


Checking for consistency of lorenz curve estimation: GQ Lorenz Curve
L(0;pi)=0: OK
L(1;pi)=1: OK (value=   1.2945)
L'(0+;pi)>=0: OK
L''(p;pi)>=0 for p within (0,1): OK

Checking for consistency of lorenz curve estimation: Beta Lorenz curve
L(0;pi)=0: OK (automatically satisfied by the functional form)
L(1;pi)=1: OK (automatically satisfied by the functional form)
L'(0+;pi)>=0: OK
L''(p;pi)>=0 for p within (0,1): OK


Estimated Poverty and Inequality Measures:

-------------------------------------------------------------------
          |                          Model                         
Indicator |         Microdata    QG Lorenz Curve  Beta Lorenz Curve
----------+--------------------------------------------------------
   FGT(0) |          39.28425           39.40078           40.33944
   FGT(1) |          7.118466           7.082356           7.115139
   FGT(2) |          1.900955           1.906036            1.90722
     Gini |          .1339824           .1390293           .1340974
-------------------------------------------------------------------
Mean Income/Expenditure:           214.28


Estimated Elasticities:

----------------------------------------------------------------------------------------
          |                                Type and Model                               
          | ----- with respect to the Mean -----    ----- with respect to the Gini -----
Indicator |   QG Lorenz Curve  Beta Lorenz Curve      QG Lorenz Curve  Beta Lorenz Curve
----------+-----------------------------------------------------------------------------
   FGT(0) |         -3.684952          -3.738047             .2630958           .2668867
   FGT(1) |         -4.563231          -4.669523               1.3972           1.404789
   FGT(2) |         -5.431503          -5.461267              2.53059           2.532715
----------------------------------------------------------------------------------------
r; t=8.34 22:22:01



r(data)[20,6]
__0000121	ac_prop_sc~1	maxscore_lp1	ac_prop_pop1	ac_mean_sc~1	mean_score~p
r1             5	2.7712476	131.42996	4.9999552	118.76535	118.76535
r2            10	6.0224633	146.478	9.9997368	129.05241	139.33983
r3            15	9.581459	158.40605	14.999667	136.87703	152.52609
r4            20	13.39813	168.33954	19.999727	143.54916	163.56491
r5            25	17.429539	177.21558	24.999672	149.39365	172.77151
r6            30	21.665108	185.70107	29.999802	154.74727	181.51437
r7            35	26.088673	193.41061	34.999645	159.72353	189.58174
r8            40	30.691652	201.00781	39.999691	164.41603	197.26297
r9            45	35.465393	208.02715	44.999638	168.87926	204.58504
r10            50	40.400276	214.64073	49.999756	173.13985	211.48386
r11            55	45.48563	221.33997	54.999619	177.2128	217.9433
r12            60	50.728893	228.27083	59.99976	181.17006	224.69844
r13            65	56.134205	235.06494	64.999725	185.05321	231.65117
r14            70	61.701004	242.10515	69.999825	188.8756	238.5654
r15            75	67.442589	249.84494	74.999817	192.68794	246.06097
r16            80	73.372734	258.58347	79.999863	196.52869	254.13914
r17            85	79.522865	269.24316	84.999977	200.472	263.56326
r18            90	85.916794	280.38959	89.999779	204.5583	274.02832
r19            95	92.65181	297.21609	94.999962	208.98303	288.62469
r20           100	100	.	99.999992	214.27948	314.91144
r; t=0.02 22:15:24


ac_prop_pop1	ac_prop_sc~1
4.9999552	2.7712476
9.9997368	6.0224633
14.999667	9.581459
19.999727	13.39813
24.999672	17.429539
29.999802	21.665108
34.999645	26.088673
39.999691	30.691652
44.999638	35.465393
49.999756	40.400276
54.999619	45.48563
59.99976	50.728893
64.999725	56.134205
69.999825	61.701004
74.999817	67.442589
79.999863	73.372734
84.999977	79.522865
89.999779	85.916794
94.999962	92.65181
99.999992	100






**********************************************************************************************
**                                   Basic Information                                      **
**********************************************************************************************

----------------- Dataset Information -----------------
                         Economy: 
                    Economy dode: 
                       Data Year: 
                        Coverage: UnDefined
             Welfare measurement: UnDefined
                     Data format: Grouped
                     Data source: User provided
                  Data time span: UnDefined
-------------------------------------------------------


----------- Distribution ----------
   i          P             L    
-----------------------------------
   1    0.04999955    0.02771248
   2    0.09999737    0.06022463
   3     0.1499967    0.09581459
   4     0.1999973     0.1339813
   5     0.2499967     0.1742954
   6      0.299998     0.2166511
   7     0.3499965     0.2608867
   8     0.3999969     0.3069165
   9     0.4499964     0.3546539
  10     0.4999976     0.4040028
  11     0.5499962     0.4548563
  12     0.5999976     0.5072889
  13     0.6499973     0.5613421
  14     0.6999983       0.61701
  15     0.7499982     0.6744259
  16     0.7999986     0.7337273
  17     0.8499998     0.7952287
  18     0.8999978     0.8591679
  19     0.9499996     0.9265181
  20             1             1
-----------------------------------


**********************************************************************************************
**                             General Quadratic Lorenz curve                               **
**********************************************************************************************

--------------- Regression result -------------
 Ymean (Mean of dependent variable): 0.169598
                   SST around ymean: 0.09330707
         SSE (sum of squared error): 3.469285E-07
            Mean squared error: MSE: 2.168303E-08
      Root mean squared error: RMSE: 0.0001472516
                      R-squared: R2: 0.9999963
-----------------------------------------------
      Coefficient   Standard error     t-ratio
-----------------------------------------------
 A       1.14807      0.0050039        229.435
 B      -1.99792      0.0023046       -866.918
 C      0.146473      0.0070504        20.7752
-----------------------------------------------



-------------------------------  Summary -------------------------------
                                                  Mean: 214.28
   overall sum of squared error of fitted lorenz curve: 2.23841E-06
      SSE of fitted lorenz curve up to headcount index: 6.03309E-07
        input poverty line Z which is within the range: (110.394, 308.656)
                              Validity of lorenz curve: Valid
                         Normality of poverty estimate: Normal
------------------------------------------------------------------------

------------------------- Distributional Estimation --------------------
                                         Gini index(%): 13.3912
                         median income(or expenditure): 214.192301697823
                                             MLD index: 0.0304483
                                 polarization index(%): 11.5778
                           distribution corrected mean: 185.585
            mean income/expenditure of the poorest 50%: 173.186
                                       estimate median: 214.192
------------------------------------------------------------------------

--------------------------------------- Decile (%) -------------------------------------------
      5.98486  7.38747  8.31147  9.04138  9.68593  10.3061  10.9517  11.6842  12.6141  14.0329
----------------------------------------------------------------------------------------------

---------------------------- Poverty Estimation ------------------------
                                          Poverty line: 200
                                         Headcount(HC): 39.4004
                                      Poverty gap (PG): 7.08228
                                     PG squared (FGT2): 1.90601
                                            Watt index: 0.085638
------------------------------------------------------------------------

   ------------- Elasticities with respect to  ----------
    Index	              Mean consumption    Gini index
   ------------------------------------------------------
    Headcount(HC)         -3.68497         0.263107
    Poverty gap (PG)      -4.56324          1.39722
    PG squared (FGT2)     -5.43152          2.53061
   ------------------------------------------------------



**********************************************************************************************
**                                   Beta Lorenz curve                                      **
**********************************************************************************************

--------------- Regression result -------------
 Ymean (Mean of dependent variable): -2.737216
                   SST around ymean: 3.764891
         SSE (sum of squared error): 0.001190196
            Mean squared error: MSE: 7.438726E-05
      Root mean squared error: RMSE: 0.008624805
                      R-squared: R2: 0.9996839
-----------------------------------------------
      Coefficient   Standard error     t-ratio
-----------------------------------------------
 A      -1.14213      0.0073633       -155.111
 B      0.867374      0.0040579        213.747
 C      0.856652       0.004058        211.103
-----------------------------------------------

------ The implied Beta lorenz curve ---------
         Theta: 0.3191401
         Gamma: 0.8673738
         Delta: 0.856652
----------------------------------------------


-------------------------------  Summary -------------------------------
                                                  Mean: 214.28
   overall sum of squared error of fitted lorenz curve: 4.78169E-06
      SSE of fitted lorenz curve up to headcount index: 2.32875E-06
        input poverty line Z which is within the range: (70.2853, 309.052)
                              Validity of lorenz curve: Valid
                         Normality of poverty estimate: Normal
------------------------------------------------------------------------

------------------------- Distributional Estimation --------------------
                                         Gini index(%): 13.4097
                         median income(or expenditure): 213.836105718637
                                             MLD index: 0.0304786
                                 polarization index(%): 11.8469
                           distribution corrected mean: 185.546
            mean income/expenditure of the poorest 50%: 172.879
                                       estimate median: 213.836
------------------------------------------------------------------------

--------------------------------------- Decile (%) -------------------------------------------
      6.04261  7.43067  8.25201  8.96853  9.64572  10.3137  10.9965  11.7258  12.5727  14.0517
----------------------------------------------------------------------------------------------

---------------------------- Poverty Estimation ------------------------
                                          Poverty line: 200
                                         Headcount(HC): 40.3391
                                      Poverty gap (PG): 7.11506
                                     PG squared (FGT2): 1.90719
                                            Watt index: 0.0835319
------------------------------------------------------------------------

   ------------- Elasticities with respect to  ----------
    Index	              Mean consumption    Gini index
   ------------------------------------------------------
    Headcount(HC)         -3.43191         0.245038
    Poverty gap (PG)      -4.66954          1.40481
    PG squared (FGT2)     -5.46128          2.53274
   ------------------------------------------------------



**********************************************************************************************
**                                      Final Result                                        **
**********************************************************************************************

 Distributional estimates use GQ (Both are valid, but GQ fits better)
 Poverty estimates use GQ (Both are valid and normal, but GQ fits better.)

-------------------------------  Summary -------------------------------
                                                  Mean: 214.28
   overall sum of squared error of fitted lorenz curve: 2.23841E-06
      SSE of fitted lorenz curve up to headcount index: 6.03309E-07
        input poverty line Z which is within the range: (110.394, 308.656)
                              Validity of lorenz curve: Valid
                         Normality of poverty estimate: Normal
------------------------------------------------------------------------

------------------------- Distributional Estimation --------------------
                                         Gini index(%): 13.3912
                         median income(or expenditure): 214.192301697823
                                             MLD index: 0.0304483
                                 polarization index(%): 11.5778
                           distribution corrected mean: -1
            mean income/expenditure of the poorest 50%: 173.186
                                       estimate median: 214.192
------------------------------------------------------------------------

--------------------------------------- Decile (%) -------------------------------------------
      5.98486  7.38747  8.31147  9.04138  9.68593  10.3061  10.9517  11.6842  12.6141  14.0329
----------------------------------------------------------------------------------------------

---------------------------- Poverty Estimation ------------------------
                                          Poverty line: 200
                                         Headcount(HC): 39.4004
                                      Poverty gap (PG): 7.08228
                                     PG squared (FGT2): 1.90601
                                            Watt index: 0.085638
------------------------------------------------------------------------

   ------------- Elasticities with respect to  ----------
    Index	              Mean consumption    Gini index
   ------------------------------------------------------
    Headcount(HC)         -3.68497         0.263107
    Poverty gap (PG)      -4.56324          1.39722
    PG squared (FGT2)     -5.43152          2.53061
   ------------------------------------------------------


*/
   
   
estout gqg , cells(b(star fmt(%9.3f)) se(par))                ///
          stats(r2_a N, fmt(%9.3f %9.0g) labels("Adj. R-squared"))      ///
          legend label collabels(none) varlabels(_cons Constant)

		  
		  
estout blcg, cells(b(star fmt(%9.3f)) se(par))                ///
          stats(r2_a N, fmt(%9.3f %9.0g) labels("Adj. R-squared"))      ///
          legend label collabels(none) varlabels(_cons Constant)

		  
	estout blcg, cells("b(star fmt(%9.3f)) se t p")                ///
          stats(r2_a N, fmt(%9.3f %9.0g) labels("Adj. R-squared"))      ///
          legend label  varlabels(_cons Constant)
