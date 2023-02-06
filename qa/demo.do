*** Code to replicate error in JP's machine


global code "C:\Users\wb255520\GitHub\myados\groupdata\src"
global data "C:\Users\wb255520\GitHub\myados\groupdata\qa"

cd ${path}


* load demo dataset
use "${data}\demo", clear

* refress ado file 
do "${code}\groupdata.ado"

* this code will run with the ado asis
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure
* this coder will not run unless you disable the braket in line 1586
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) grouped nofigure 


groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) grouped nofigure

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure 

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure bins(15)

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure bins(15)

* generated groupped data for check from group data to group data estimates
alorenz score_lp [aw=learner_weight_lp] if idgrade == 5, fullview points(15)
mat a = r(lorenz1) 
svmat double a, names(col)
						
do "${myados}\groupdata\src\groupdata.ado"

* mean  (Type 1: OK) accepts only AW
groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200) mean(214.28) type(1) nofigure nochecks noelasticities binvar(xscore_lp1)
						
* mean  (Type 2: OK) accepts only AW
groupdata prop_score_lp 	[aw=prop_pop ] 		, z(200) mean(214.28) type(2) nofigure nochecks noelasticities binvar(xscore_lp1)
						
* mean  (Type 5: Fail) noweight
groupdata mean_score_lp 						, z(200) mean(214.28) type(5) nofigure nochecks noelasticities binvar(xscore_lp1)

* mean  (Type 5: OK) pw
groupdata mean_score_lp 	[pw=prop_pop]		, z(200) mean(214.28) type(5) nofigure nochecks noelasticities binvar(xscore_lp1)


* max 	(Type 6: OK)

tabstat score_lp [aw= learner_weight_lp ] , by(idgrade) stat(mean min max)

groupdata maxscore_lp	 						, z(200) mean(214.28) type(5) nofigure nochecks noelasticities binvar(xscore_lp1)
groupdata maxscore_lp	 						, z(200) mean(214.28) type(6) nofigure nochecks noelasticities min(92.0619) max(334.22818) binvar(xscore_lp1)



* mean  (Type 1: OK) accepts only AW
groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200) mean(214.28 240 260 280) type(1) nofigure nochecks noelasticities binvar(xscore_lp1)
						

* mean  (Type 1: OK) accepts only AW
groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200 205 210) mean(214.28 240 260 280) type(1) nofigure nochecks noelasticities binvar(xscore_lp1)
						
											
						
/*

* groupdata2 is the same as groupdata however, the bracket in line 1586 is commented out
groupdata2 score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) grouped nofigure
* howevever in this code the option BENCHMAKR will generate an error
groupdata2 score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group benchmark nofigure 

*/



* refress ado file 
do "${code}\groupdata.ado"
* mean  (Type 1: OK) accepts only AW
groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200) mean(214.28) type(1) nofigure nochecks noelasticities binvar(xscore_lp1)



* refress ado file 
do "${code}\groupdata.ado"

groupdata  ac_prop_score_lp , z(200) mean(214.28) sd(.5) ///
			coefgq( 1.115647386207366  -1.975629715228501  .1380477078709877 ) ///
			coefb(.8645672895800628  .837871913505847 -1.149206699669331)


groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200) mean(214.28) type(1) nofigure nochecks noelasticities ///
			coefb(.8645672895800628  .837871913505847 -1.149206699669331)


groupdata ac_prop_score_lp 	[aw=ac_prop_pop] 	, z(200) mean(214.28) type(1) nofigure nochecks noelasticities ///
			coefgq( 1.115647386207366  -1.975629715228501  .1380477078709877 ) 
		