*-----------------------------------------------------------------------------
*	Title: 	Groupdata QA
*	Data:	April 6th 2020
* 	Author: Joao Pedro Azevedo
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
* Learning Poverty Simulation (distributionally neutral)

use "$output\score2017", clear
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) benchmark group 
groupdata score_lp [aw=learner_weight_lp] if idgrade == 9, z(200) benchmark group 

groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(207.9) benchmark group 


use "$output\score2011", clear
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) group bins(10) benchmark
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(214.8) group 
groupdata score_lp [aw=learner_weight_lp] if idgrade == 5, z(200) mu(207.9) group 
  
*-----------------------------------------------------------------------------