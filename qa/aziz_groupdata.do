global upi   "`c(username)'"

* Joao Pedro
if "$upi" == "wb255520" {
	global root "C:\Users\wb255520\GitHub\myados\groupdata"
}


* to run in JP's machince

do "$root\src\groupdata.ado"

use "$root\qa\test_group.dta", clear