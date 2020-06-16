*-------------------------------------------------------------------------------
*** Example to deboug
*-------------------------------------------------------------------------------

global upi   "`c(username)'"

* Joao Pedro
if "$upi" == "wb255520" {
	global root "C:\Users\wb255520\GitHub\myados\groupdata"
}

* Aziz
if "$upi" == "wb408971" {
	global root "C:\Users\wb408971\Documents\GitHub\groupdata"
}


*-------------------------------------------------------------------------------
* to set parameters in the code 
*-------------------------------------------------------------------------------

do "$root\src\groupdata.ado"

use "$root\qa\test_group.dta", clear

*-------------------------------------------------------------------------------
* run groupdata
*-------------------------------------------------------------------------------

groupdata var2017 [pw=wtg], z(4950)  mean(7542) type(5) binvar(decile) nofigures


