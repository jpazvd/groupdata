*-----------------------------------------------------------------------------
*! v 2.8  28apr2020             by  JPA
* support welfare estimations based on provided coefficients
* add multiple mean options
* add debug milestones
* return matrix includes mean, sd, and povline
* v 2.7  24apr2020             by  JPA
* fix estiamtes using unit record data
* estimate multiple lines
* v 2.6  16apr2020             by  JPA groupdata
*   added Beta and Quadratic Lorenz regression coefficient in the return list
* v 2.5	14apr2020				by 	JPA		groupdata
*   added the cleanversion function
* v 2.4   	10apr2020			by JPA
*	lnsd: fixed
*	mz 	: multiple poverty lines
*   mmu	: multiple mean values
* v 2.3.1   08apr2020			by JPA
*   add SD was an option when estimating groupped data
*	Remove PW since it is not supported by SUMARIZE
*   Type 1 grouped data: P=Cumulative proportion of population, L=Cumulative
*		proportion of income held by that proportion of the population
*   Type 2 grouped data: Q=Proportion of population, R=Proportion of incometype
*   Type 5 grouped data: W=Percentage of the population in a given interval of
*		incomes, X=The mean income of that interval.
*   Type 6 grouped data: W=Percentage of the population in a given interval of
*		incomes, X=The max income of that interval.
*   Unit record data: Percentage of the population with same income level,
*		The income level.
*		improve the layout
* v 2.2   06apr2020				by JPA
*   dependencies checks run quietly
*   apoverty and ainequal added to the dependencies check
* v 2.1   05apr2020				by JPA
*   changed ado name from grouppov to groupdata
* v 2.0   02apr2020				by JPA
*   changes made to use this method to estimate learning poverty
* 	add support to aweight
*   replace wtile2 by alorenz
*   add microdata value as benchmark
* v 1.1   14jan2014				by SM and JPA
*   change ado name from povcal to grouppov
*   technical note on Global Poverty Estimation: Theoratical and Empirical
*   Validity of Parametric Lorenz Curve Estiamtes and Revisitng Non-parametric
*   techniques. (January, 2014), for discussions on the World Bank Global
*   Poverty Monitoring Working Group.
* v 1.0   02fev2012				by SM and JPA
*   povcal.ado created by Joao Pedro Azevedo (JPA) and Shabana Mitra (SM)
*-----------------------------------------------------------------------------

cap program drop groupdata
program define groupdata, rclass

  version 15.0

  syntax [ varlist(numeric min=1 max=1) ]         ///
    [in] [if]                   ///
    [fweight aweight pweight]   ///
      ,                         ///
        Zl(string)            	///
          [						///
    			Mean(string)    ///
				GROUPed         ///
				BINs(real -99)  ///
				REGress			///
    			BENCHmark		///
    			NOFIGures		///
    			UNITRECord		///
    			type(string) 	///
    			NOElasticities	///
    			NOLorenz		///
    			NOChecks		///
    			min(string)		///
    			max(string)		///
    			sd(real -99)	///
				coefb(string)	///
				coefgq(string)  ///
    			debug			///
				binvar(string)	///
          ]

preserve

quietly {

*-----------------------------------------------------------------------------
* 	Temp names
*-----------------------------------------------------------------------------

	tempname A  gq cofb cof  gqg cofbg tmp rtmp
	tempvar  temp touse rnd lninc lnmpce mpce pp pw L p y1 y2 a b c  x1 x2  Lg pg yg ag bg cg yg2 x1g x2g  type2 model var value
	
	local skip = 0
	
  *-----------------------------------------------------------------------------
  * Set default values
  *-----------------------------------------------------------------------------

  * set defaut value for the mean
  if ("`mean'" == "") {
		local meanint "-99"
  }
  if ("`mean'" != "") {
		local meanint "`mean'"
  }  

*-----------------------------------------------------------------------------
* Check options
*-----------------------------------------------------------------------------

	if ("`meanint'" != "-99") & ("`benchmark'" != "") {
		noi di ""
    di as err "Option benchmark only works with original mean."
    exit 198
		noi di ""
	}

	if ("`meanint'" == "-99") & ("`type'" != "") {
		noi di ""
    di as err "Estimates based on group data require the user to provide the mean value of the distribution"
    exit 198
		noi di ""
	}
	if (strmatch(" 1 2 5 6","*`type'*") == 1) & ("`binvar'" == "") & ("`grouped'" == "") & (("`coefgq'" == "")  | ("`coefb'" == ""))  {
		noi di ""
		di as err "Please make sure you specified the binvar option."
		exit 198
	}

	if (strmatch(" 1 2 5 6","*`type'*") == 0) {
		noi di ""
		di as err "Please select a valid data type. see help."
		noi di ""
		noi di as text "Type 1 grouped data: " as res "P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population"
		noi di as text "Type 2 grouped data: " as res "Q=Proportion of population, R=Proportion of incometype"
		noi di as text "Type 5 grouped data: " as res "W=Percentage of the population in a given interval of incomes, X=The mean income of that interval"
		noi di as text "Type 6 grouped data: " as res "W=Percentage of the population in a given interval of incomes, X=The max income of that interval"
		noi di ""
		exit 198
	}
	
	* check coef option / both vectors must be specified
	if ("`coefb'" != "") | ("`coefbgq" != "") & ("`type'" == "") & ("`grouped'" == "") {
		if ("`coefb'" == "") {
			noi di ""
			di as err "Both vectors of coeficients must be specified. see help."
			exit 198
		}
		if ("`coefgq'" == "") {
			noi di ""
			di as err "Both vectors of coeficients must be specified. see help."
			exit 198
		}
		local skip = 1
		local type = -88
	}
*-----------------------------------------------------------------------------
* 	Weights
*-----------------------------------------------------------------------------

	if (`skip' != 1) {
 

		* keep original weights
		local wtg2 = "`weight'"
		local weight2 = "`weight'"
		local exp2 = subinstr("`exp'","=","",.)

		* set-up weights when it is not available
		if ("`weight'" == "") {
			tempvar wtg
			gen `wtg' = 1
			loc weight "fw"
			loc exp    "=`wtg'"
			local pop "`wtg'"
			local `mpce' = `pop'
		}
		else {
			local pop =subinstr("`exp'","=","",.)
			local `mpce' = `pop'
	  }
		
	*-----------------------------------------------------------------------------
	* checks with Type 1 is selected
		if ("`type'" == "1") {
		   if ("`wtg2'" == "") {
				noi di as err "Type 1 only accepts accept AW."
				exit 198
			}
			if strmatch("pweight","*`wtg2'*") == 1 {
				noi di as err "Type 1 only accepts accept AW."
				exit 198
			}
			if strmatch("fweight","*`wtg2'*") == 1 {
				noi di as err "Type 1 only accepts accept AW."
				exit 198
			}
		}

	  *-----------------------------------------------------------------------------
	  * checks with Type 2 is selected
		if ("`type'" == "2") {
		if ("`wtg2'" == "") {
			noi di as err "Type 2 only accepts accept AW."
			exit 198
		}
		if strmatch("pweight","*`wtg2'*") == 1 {
			noi di as err "Type 2 only accepts accept AW."
			exit 198
		}
		if strmatch("fweight","*`wtg2'*") == 1 {
			noi di as err "Type 2 only accepts accept AW."
			exit 198
		}
		}

	*-----------------------------------------------------------------------------
	* checks with Type 5 is selected
		if ("`type'" == "5") {
			if (substr(trim("`wtg2'"),1,2) == "aw") {
				noi di as err "Type 5 does not accept AW weights. Please use either PW, FW or no weights."
				exit 198
			}
			if strmatch("pweight","*`wtg2'*") == 1 {
				local weight2 = "aweight"
			}
		}

	*-----------------------------------------------------------------------------
	* checks with Type 6 is selected
		if ("`type'" == "6") {
			if (substr(trim("`wtg2'"),1,2) == "aw") {
				noi di as err "Type 6 does not accept AW weights. Please use either PW, FW or no weights."
				exit 198
			}
			if strmatch("pweight","*`wtg2'*") == 1 {
				local weight2 = "aweight"
			}
		}

	*-----------------------------------------------------------------------------
	* Download and install required user written ado's
	*-----------------------------------------------------------------------------
	* Fill this list will all user-written commands this project requires

		local user_commands groupfunction alorenz which_version apoverty ainequal estout

	* Loop over all the commands to test if they are already installed, if not, then install
		qui foreach command of local user_commands {
			cap which `command'
			if _rc == 111 {
				ssc install `command'
		   }
		 else {
		  * check version number
			  which_version groupfunction
		  * clean version number
			  cleanversion, input(`s(version)') lookfor(.)
			* condition
			  if  (`r(result1)' < 2.0) {
				  ado update groupfunction , update
			  }
		  * check version number
			  which_version alorenz
		  * clean version number
			  cleanversion, input(`s(version)') lookfor(.)
		  * condition
			  if  (`r(result1)' < 3.1) {
				  ado update alorenz , update
			  }
		  }
	  }

	*-----------------------------------------------------------------------------
	* 	Display Options
	*-----------------------------------------------------------------------------

		* show regression outputs
		if ("`regress'" != "") {
			loc noireg "noi "
		}
		else {
			loc noireg ""
		}

		* does not show lorenz
		if ("`nolorenz'" != "") {
			loc noilor ""
		}
		else {
			loc noilor "noi"
		}

		* does not show elasticities
		if ("`noelasticities'" != "") {
			loc noelast ""
		}
		else {
			loc noelast "noi"
		}

		* does not show checks
		if ("`nochecks'" != "") {
			loc nocheck ""
		}
		else {
			loc nocheck "noi"
		}

		* debug
		if ("`debug'" == "") {
			loc noidebug 
		}
		else {
			loc noidebug noi:
		}

	*-----------------------------------------------------------------------------
	* 	Filters
	*-----------------------------------------------------------------------------

		tokenize `varlist'
		local inc `1'
		mark `touse' `if' `in' [`weight'`exp']
		* remove missing values from estiamte
		markout `touse'  `varlist'

	*-----------------------------------------------------------------------------
	* 	Data sort
	*-----------------------------------------------------------------------------

		set seed 1234568
	  gen double `rnd' = uniform()		if `touse'
	  gen `lninc' 	= ln(`inc') 			if `touse'
		gen `lnmpce' 	= ln(`inc') 			if `touse'
	  sort `inc' `rnd'

	*-----------------------------------------------------------------------------
	* 	Unit Record estimations used to benchmark results
	*-----------------------------------------------------------------------------

	  `noidebug' di as text "Unit Record estimations used to benchmark results"

		qui if ("`benchmark'" == "benchmark") {
		* create  counter
		local ppp = 0
		if ("`noidebug'"==""){
			foreach z in `zl' {
			
				local pl "pl`ppp'"
				* unit record poverty estimates
				apoverty `inc' [`weight'`exp'] 	if `touse', line(`z')  fgt3  pgr
				local `pl'afgt0 = r(head_1)
				local `pl'afgt1 = r(pogapr_1)
				local `pl'afgt2 = r(fogto3_1)
				* unit record inequality estimates
				ainequal `inc' [`weight'`exp']  if `touse'
				local `pl'agini = r(gini_1)
				* create row labels for output matrix
				local rownames_unitrecord " fgt0 fgt1 fgt2 gini "
				local ppp = `ppp' + 1
	*			`noidebug' dis as error "AQUI"
			}
	*		`noidebug' dis as error "AQUI2"
		}
		else{
			foreach z in `zl' {
			
				local pl "pl`ppp'"
				* unit record poverty estimates
				apoverty `inc' [`weight'`exp'] 	if `touse', line(`z')  fgt3  pgr
				local `pl'afgt0 = r(head_1)
				local `pl'afgt1 = r(pogapr_1)
				local `pl'afgt2 = r(fogto3_1)
				* unit record inequality estimates
				ainequal `inc' [`weight'`exp']  if `touse'
				local `pl'agini = r(gini_1)
				* create row labels for output matrix
				local rownames_unitrecord " fgt0 fgt1 fgt2 gini "
				local ppp = `ppp' + 1
	*			`noidebug' dis as error "AQUI"
			}		
		}
		
		}

	*-----------------------------------------------------------------------------
	* 	Unit Record
	*-----------------------------------------------------------------------------

	  if ("`unitrecord'" == "unitrecord") {

		`noidebug' di as text "Unit Record estimations"
			noi di ""
			noi di ""
			noi di "Estimation using unit record information."

		************************************
		** cumulative distribution
		************************************

		egen double `pw' = pc(`inc')			if `touse', prop
		egen double `pp' = pc(`pop')			if `touse', prop

		gen double 	`L' = `pw'					if `touse'
		replace 	`L' = `pw'+`L'[_n-1] in 2/l	if `touse'

		gen double 	`p' = `pp'					if `touse'
		replace 	`p' = `pp'+`p'[_n-1] in 2/l	if `touse'

		************************************
		** generate variables (GQ Lorenz Curve)
		************************************

		gen double `y1' = `L'*(1-`L')			if `touse'
		gen double `a' 	= ((`p'^2)-`L')			if `touse'
		gen double `b' 	= `L'*(`p'-1)			if `touse'
		gen double `c' 	= (`p'-`L')				if `touse'

		************************************
		** generate variables Beta Lorenz Curve
		************************************

		gen double `y2'	=	ln(`p'-`L')			if `touse'
		gen double `x1'	=	ln(`p')				if `touse'
		gen double `x2'	=	ln(1-`p')			if `touse'

		local last = _N-1

	  ************************************
		** Plot Figure
	  ************************************

			if ("`nofigures'" == "") {

				local mustr = strofreal(`mu',"%9.2f")
				local intercept00 = _N + 1
				replace `L' = 0 in `intercept00'
				replace `p' = 0 in `intercept00'

				graph twoway lowess `L' `p'		if `touse', 						///
					ytitle("Lorenz") xtitle("Population (Cumulative)") 				///
					note("mean: `mustr' [`bins' bins]") name(lorenz, replace)

				kdensity `inc' 					if `touse', 						///
					xline(`z') xtitle("`inc'") name(pdf, replace)

				graph twoway lowess `inc' `p'	if `touse', 						///
					yline(`z') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
					note("mean: `mustr' [`bins' bins]") name("pen", replace)

			}

		************************************
		** Estimation: GQ Lorenz Curve
		************************************
		`noidebug' di as text "Unit Record : Estimation: GQ Lorenz Curve"

			label var `y1' 	"`inc'"
			label var `a'  	"A"
			label var `b' 	"B"
			label var `c'	"C"

		qui reg `y1' `a' `b' `c' in 1/`last' if `touse', noconstant
		est store coefgq
		mat `gq' = e(b)
		mat `cof' = e(b)

		************************************
		** Estimation: Beta Lorenz Curve
		************************************

		`noidebug' di as text "Unit Record : Beta Lorenz Curve"

			label var `y2' 	"`inc'"
			label var `x1'	"B"
			label var `x2'	"C"

		qui reg `y2' `x1' `x2' in 1/`last' if `touse'
		est store coefbeta
		mat `cofb' = e(b)

	  }

	*-----------------------------------------------------------------------------
	* Group data provided
	* Need to specify the Type of Group data provided
	*-----------------------------------------------------------------------------

	  qui if ("`type'" != "") {

		`noidebug' di as text "Group Data : Type `type'"

			noi di ""
			noi di ""
			noi di "Estimation using provided distribution (Type `type')"

			if ("`type'" == "1") {
				noi di ""
				noi di "Type 1 grouped data: P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population"
			}
			if ("`type'" == "2") {
				noi di ""
				noi di "Type 2 grouped data: Q=Proportion of population, R=Proportion of incometype"
			}
			if ("`type'" == "5") {
				noi di ""
				noi di "Type 5 grouped data: W=Percentage of the population in a given interval of incomes, X=The mean income of that interval"
			}
			if ("`type'" == "6") {
				noi di "Type 6 grouped data: W=Percentage of the population in a given interval of incomes, X=The max income of that interval"
			}

			
	************************************
	** Sort database according to binidentifier
	************************************
		
		tempvar ccc
		gen `ccc' = `binvar' == .
		gsort `ccc' -`touse' `binvar'
	
			
	************************************
	** Type 1 grouped data: P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population
	************************************

		if ("`type'" == "1") {
			sum `inc'									if `touse'
			local bins = r(N)
			local last = `bins'-1
			if (substr(trim("`wtg2'"),1,2) == "aw") {
				gen `Lg' = `inc'/100					in 1/`bins'
				gen `pg' = `exp2'/100					in 1/`bins'
			}
		}

	************************************
	** Type 2 grouped data: Q=Proportion of population, R=Proportion of incometype
	************************************

		if ("`type'" == "2") {
			sum `inc'										if `touse'
			local bins = r(N)
			local last = `bins'-1
			if (substr(trim("`wtg2'"),1,2) == "aw") {
				gen `Lg' = `inc'/100						in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1] in 2/l	in 2/`bins'
				gen `pg' = `exp2'/100						in 1/`bins'
				replace `pg' = `pg'[_n]+`pg'[_n-1] in 2/l	in 2/`bins'
			}
		}

	************************************
	** Type 5 grouped data: W=Percentage of the population in a given interval of incomes, X=The mean income of that interval
	************************************

		if ("`type'" == "5") {
		  * identify number of bins
			sum `inc'											if `touse'			
			local bins = r(N)
			local last = `bins'-1
			if ("`wtg2'" == "") {
				gen double 	`pg' 	= 	1/`bins'				in 1/`bins'
				replace 	`pg' = `pg'[_n]+`pg'[_n-1] 			in 2/`bins'	
				sum `inc'										in 1/`bins'
				local sumL = r(sum)								
				gen double 	`Lg' = `inc'/`sumL'					in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1] 				in 2/`bins'
				
				`noidebug' di as text `"("`wtg2'" == "")"'
				`noidebug' list  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse' if `touse'
				`noidebug' sum  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse'  if `touse'
			}

			if (substr(trim("`wtg2'"),1,2) == "pw") {
				tempvar LLLLL PPPPP
				gen 	`pg' = `exp2'							in 1/`bins'
				replace `pg' = `pg'[_n]+`pg'[_n-1] 				in 2/`bins'
				gen double `PPPPP' = `exp2'*`inc'*100000		in 1/`bins'
				sum `PPPPP'										in 1/`bins'
				local sumL = r(sum)
				gen double 	`LLLLL' = `PPPPP'/`sumL'			in 1/`bins'
				replace 	`LLLLL' = `LLLLL'[_n]+`LLLLL'[_n-1] in 2/`bins'
				gen double `Lg' = `LLLLL'
				`noidebug' di as text `"(substr(trim("`wtg2'"),1,2) == "pw")"'
				`noidebug' list  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse' if `touse'
			}


			if (substr(trim("`wtg2'"),1,2) == "fw") {
				sum `exp2'									in 1/`bins'
				local sumP = r(sum)
				gen double 	`pg' = `exp2'/`sumP'			in 1/`bins'
				replace `pg' = `pg'[_n]+`pg'[_n-1] in 2/l	in 2/`bins'
				sum `inc' 	[`weight'`exp']					in 1/`bins'
				local sumL = r(sum)
				gen doulbe 	`Lg' = `inc'/`sumL'				in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1] in 2/l	in 2/`bins'
				`noidebug' di as text `"(substr(trim("`wtg2'"),1,2) == "fw")"'
				`noidebug' list  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse' if `touse'
			}
		}

	************************************
	** Type 6 grouped data: W=Percentage of the population in a given interval of incomes, X=The max income of that interval
	************************************

		tempvar inc2 delta
		if ("`type'" == "6") {
		  * mean welare
		  * identify number of bins
			sum `inc'															if `touse'
			local bins = r(N)
			local bins = `bins'+1
			local last = `bins'-1
		  *identify min and max per bin
			noi di "min: " `min'
			noi di "max: " `max'
			noi di "bins: " `bins'
		  * if weights are not specified
			if ("`wtg2'" == "") {
				gen double 	`pg' 	= 	1/`bins'								in 1/`bins'
				gen 	double `delta' = .
				replace `delta' = (`inc'[_n]-`min')			/2 					in 1
				replace `delta' = (`inc'[_n]-`inc'[_n-1])	/2 					in 1/`bins'
				replace `delta' = (`max'	-`inc'[_n-1])	/2 					in `bins'		
				replace `pg' = `pg'[_n]+`pg'[_n-1] 								in 2/`bins'						
				gen double `inc2' = .											
				replace `inc2' = `inc' - `delta'								in 1/`last'		
				replace `inc2' = `max' - `delta'								in `bins'		
				sum `inc2'														in 1/`bins'
				local sumL = r(sum)
				gen double 	`Lg' = `inc2'/`sumL'								in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1] in 2/l						in 2/`bins'
				`noidebug' list `pg' `inc' `delta' `inc2' `Lg' 					if `touse'
			}

			if (substr(trim("`wtg2'"),1,2) == "pw") {
				tempvar LLLLL PPPPP
				gen double 	`pg' 	= 	`exp2'									in 1/`bins'
				gen 	double `delta' = .										
				replace `delta' = (`inc'[_n]-`min')			/2 					in 1			
				replace `delta' = (`inc'[_n]-`inc'[_n-1])	/2 					in 2/`last'		
				replace `delta' = (`max'	-`inc'[_n-1])	/2 					in `bins'		
				replace `pg' = `pg'[_n]+`pg'[_n-1] 								in 2/`bins'			
				gen double `inc2' = .											
				replace `inc2' = `inc' - `delta'								in 1/`last'		
				replace `inc2' = `max' - `delta'								in `bins'		
				gen double `PPPPP' = `exp2'*`inc2'*100000						in 1/`bins'
				sum `PPPPP'														in 1/`bins'
				local sumL = r(sum)
				gen double 	`LLLLL' = `PPPPP'/`sumL'							in 1/`bins'
				replace 	`LLLLL' = `LLLLL'[_n]+`LLLLL'[_n-1] 				in 2/`bins'
				gen double `Lg' = `LLLLL'										in 1/`bins'
				`noidebug' list `pg' `inc' `delta' `inc2' `Lg' 					if `touse'
			}

			if (substr(trim("`wtg2'"),1,2) == "fw") {
				sum `exp2'														in 1/`bins'
				local sumP = r(sum)
				gen double 	`pg' = `exp2'/`sumP'								in 1/`bins'

				gen 	double `delta' = .										
				replace `delta' = (`inc'[_n]-`min')			/2 					in 1			
				replace `delta' = (`inc'[_n]-`inc'[_n-1])	/2 					in 2/`last'		
				replace `delta' = (`max'	-`inc'[_n-1])	/2 					in `bins'		
				replace `pg' = `pg'[_n]+`pg'[_n-1] 								in 2/`bins'
				gen double `inc2' = .											
				replace `inc2' = `inc' - `delta'								in 1/`last'		
				replace `inc2' = `max' - `delta'								in `bins'		
				sum `inc2'		[`weight'`exp']									in 1/`bins'
				local sumL = r(sum)
				gen double 	`Lg' = `inc2'/`sumL'								in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1] 								in 2/`bins'				
				`noidebug' list `pg' `inc' `delta' `inc2' `Lg' 					if `touse'
			}
		}

	  ************************************
	  ** Generate the cumulative distribution
	  ************************************

		sum `pg'
		local s = r(sum)
		if (`s'>99) {
			gen double `p' = `pg'/100
		}
		else {
			gen double `p' = `pg'
		}

		sum `Lg'
		local s = r(sum)
		if (`s'>99) {
			gen double `L' = `Lg'/100
		}
		else {
			gen double `L' = `Lg'
		}

	  ************************************
	  ** Generate variables: GQ Lorenz Curve
	  ************************************

		gen double `y1' = `L'*(1-`L')
		gen double `a' = ((`p'^2)-`L')
		gen double `b' = `L'*(`p'-1)
		gen double `c' = (`p'-`L')

	  ************************************
	  ** Generate variables: Beta Lorenz Curve
	  ************************************

		gen double `y2'=ln(`p'-`L')
		gen double `x1'=ln(`p')
		gen double `x2'=ln(1-`p')

	  ************************************
		** Plot Figure
	  ************************************

		if ("`nofigures'" == "") {
			local mustr = strofreal(`mu',"%9.2f")
			local intercept00 = `bins' + 1
			replace `L' = 0 in `intercept00'
			replace `p' = 0 in `intercept00'
		  * figure 1 - Lorenz
		  graph twoway lowess `L' `p'		, 						///
				ytitle("Lorenz") xtitle("Population (Cumulative)") 				///
				note("mean: `mustr' [`bins' bins]") name(lorenz, replace)
			* figure 2 - PDF
			kdensity `inc' 					, 						///
				xline(`z') xtitle("`inc'") name(pdf, replace)
			* figure 3 - Pen's parade
			graph twoway lowess `inc' `p'	, 						///
				yline(`z') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
				note("mean: `mustr' [`bins' bins]") name("pen", replace)
		}

		`noidebug' list `Lg' `L' `pg' `p'  `y1' `a' `b' `c'  `y2' `x1' `x2' if `y1' !=. & `touse'

	************************************
	** Estimation: GQ Lorenz Curve (Group data provided)
	************************************

		`noidebug' di as text "Group data provided: GQ Lorenz Curve"

		label var `y1' 	 "`inc'"
		label var `a'  	 "A"
		label var `b' 	 "B"
		label var `c'	 "C"

		qui reg `y1' `a' `b' `c' in 1/`last' , noconstant
		est store coefgq
		mat `gq' = e(b)
		mat `cof' = e(b)

	************************************
	** Estimation: Beta Lorenz Curve (Group data provided)
	************************************

		`noidebug' di as text "Group data provided: Beta Lorenz Curve"

		label var `y2' 	"`inc'"
		label var `x1'	"B"
		label var `x2'	"C"

		qui reg `y2' `x1' `x2' in 1/`last'
		est store coefbeta
		mat `cofb' = e(b)

	  }

	*-----------------------------------------------------------------------------
	* Unite Records is provided
	* Group data is estimated by Groupdata ado
	*-----------------------------------------------------------------------------

	  qui if ("`grouped'" == "grouped") {
			noi di ""
			noi di "Estimation using grouped data..."

		** cumulative distribution (grouped data)
		if (`bins'!= 0) {
			if (`bins' == -99) {
			* if bins are not specified the default value is 20 bins
				local bins = 20
				noi di ""
				noi di "... creating groupped data with `bins' bins."
				noi di ""
				alorenz `inc' [`weight'`exp']	if `touse', points(`bins')
			}
			else {
				noi di ""
				noi di "... creating groupped data with `bins' bins."
				noi di ""
				alorenz `inc' [`weight'`exp']	if `touse', points(`bins')
			}
		}
		* extract return matrix
			mat `A' = r(lorenz1)
		* export return matrix to dataset
			svmat double `A'
		* generate return matrix of dataset
			return matrix data = `A'

	  ** generate variables (GQ Lorenz Curve) (grouped data)
		gen double `Lg' = `A'2/100
		gen double `pg' = `A'4/100
		gen double `yg' = `Lg'*(1-`Lg')
		gen double `ag' = ((`pg'^2)-`Lg')
		gen double `bg' = `Lg'*(`pg'-1)
		gen double `cg' = (`pg'-`Lg')

		** generate variables Beta Lorenz Curve (Grouped data)
		gen double `yg2' = ln(`pg'-`Lg')
		gen double `x1g' = ln(`pg')
		gen double `x2g' = ln(1-`pg')
		local lastg = `bins'-1

	************************************
	** Plot Figure
	************************************

			if ("`nofigures'" == "") {
				local mustr = strofreal(`mu',"%9.2f")
				local intercept00 = `bins'+1
				replace `Lg' = 0 in `intercept00'
				replace `pg' = 0 in `intercept00'
		  * Figure 1 - Lorenz
				graph twoway lowess `Lg' `pg', 										            ///
					ytitle("Lorenz") xtitle("Population (Cumulative)") 		      ///
					note("mean: `mustr' [`bins' bins]") name(lorenz, replace)
		  * Figure 2 - PDF
				kdensity `A'6, 														                    ///
					xline(`z') xtitle("`inc'") name(pdf, replace)
		  * Figure 3 - Pen's Parade
				graph twoway lowess `A'3 `pg', 										              ///
					yline(`z') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
					note("mean: `mustr' [`bins' bins]") name("pen", replace)
			}

	  ************************************
	  ** Estimation: GQ Lorenz Curve (grouped data)
	  ************************************

		`noidebug' di as text "Group data constructed: GQ Lorenz Curve"

			label variable `yg'   "`inc'"
			label variable `ag'		"A"
			label variable `bg' 	"B"
			label variable `cg' 	"C"

		qui reg `yg' `ag' `bg' `cg' in 1/`lastg', noconstant
		est store coefgqg
		mat `gqg' = e(b)

	  ************************************
	  ** Estimation: Beta Lorenz Curve (Grouped data)
	  ************************************

		`noidebug' di as text "Group data constructed: Beta Lorenz Curve "

			label variable `yg2' 	"`inc'"
			label variable `x1g'  "B"
			label variable `x2g'	"C"

		qui reg `yg2' `x1g' `x2g'  in 1/`lastg'
		est store coefbetag
		mat `cofbg' = e(b)

	  }
	  
	}

*-----------------------------------------------------------------------------
* Start the computation of welfare measures FGT0; FGT1; FGT2; Gini
*-----------------------------------------------------------------------------

  local ppp = 0

  * allow for multiple poverty lines
  qui foreach z in `zl' {

    `noidebug' di as text "Poverty Line : `z'"
    local pl "pl`ppp'"

*-----------------------------------------------------------------------------
* 	Mean values
*-----------------------------------------------------------------------------
	
	local mmm = 0
	
	* allow for multiple mean values
	foreach mu in `meanint' {

		`noidebug' di as text "Mean value"

		* generate mean values for unit record estimations
		if ("`type'" == "") {
		  if (`mu' == -99) {
			* generate mean and stadard deviation for unit record data
			  sum `inc' [`weight2'`exp']		if `touse'
			  local mu = `r(mean)'

			sum `lnmpce' [`weight2'`exp']		if `touse'
			local lnmu = r(mean)
			local sd   = r(sd)
			local lnsd = ln(`sd')
		  }
		  if (`mu') != -99 {
			* use the mean provided as an option
			  sum `lnmpce' [`weight2'`exp']		if `touse'
			local lnmu = ln(`mu')
			local sd   = r(sd)
			local lnsd = ln(`sd')
		  }
		}

		* generate mean values for group data estimations
		if ("`type'" != "") {
		  * mean value is provided by the command as a parameters
		    local lnmu = ln(`mu')
			local mu = `mu'
			if (`sd' == -99) {
				sum `lnmpce' [`weight2'`exp']	if `touse'
				local lnmu = ln(`mu')
				local sd   = r(sd)
				local lnsd = ln(`sd')
				*local lnsd = ln(.5)
			}
			if (`sd' != -99)  {
				local lnsd = ln(`sd')
			}
		}
			
		if (`skip' != 1) {
			*keep only group data
			keep if `touse'
		}

		 * increase the number of rows to match what is required by
		 * output matrix (32 rows)
		local N = _N
		if (`N' < 24) {
			set obs 32
		}
	
	di "`mu'"
	di "`lnmu'"
	
	
	*-----------------------------------------------------------------------------
	* 	Table 2 (Datt, 1998)
	*-----------------------------------------------------------------------------
	* 		GQ Lorenz Curve
	*-----------------------------------------------------------------------------

		`noidebug' di as text "Analytical calculations: GQ Lorenz Curve"

		if ("`coefgq'" == "") {
			if ("`grouped'" != "") {
				local a = `gqg'[1,1]
				local b = `gqg'[1,2]
				local c = `gqg'[1,3]
			}
			else {
				local a = `gq'[1,1]
				local b = `gq'[1,2]
				local c = `gq'[1,3]
			}
		}
		if ("`coefgq'" != "") {
				local a = real(trim(word("`coefgq'" ,1)))
				local b = real(trim(word("`coefgq'" ,2))) 
				local c = real(trim(word("`coefgq'" ,3)))
		}
		

		local e     = -(`a'+`b'+`c'+1)
		local m     = `b'*`b' - (4*`a')
		local n     = (2*`b'*`e') - (4*`c')
		local r     = sqrt((`n'*`n') - (4*`m'*(`e'*`e')))
		local s1    = (`r'-`n')/(2*`m')
		local s2    = -(`r'+`n')/(2*`m')

		local H = -(1/(2*`m'))*(`n'+`r'*(`b'+2*`z'/`mu')*(1/sqrt((`b'+2*`z'/`mu')*(`b'+2*`z'/`mu')-`m')))
		local lH = -(1/2)*(`b'*`H' + `e' + sqrt(`m'*`H'*`H' + `n'*`H' + `e'*`e'))
		local PG = `H'-(`mu'/`z')*`lH'
		local SPG = 2*`PG' - `H' - ((`mu'/`z')*(`mu'/`z')) * (`a'*`H' + `b'*`lH' - (`r'/16) * ln((1-`H'/`s1')/(1-`H'/`s2')))

		/*** Second derivative of Lorenz curve*/
		local ldph = ((`r'*`r')/8)*((`m'*(`H'*`H')+ `n'*`H' + `e'*`e')^(-3/2))

		/*** Gini */
		* For the GQ Lorenz curve, the Gini formulas are valid under the condition a % c $1.
		#delim ;
		if `m'<0 { ;
			local gini_tt = (`e'/2)- `n'*(`b'+2)/(4*`m') +
			((`r'^2)/(8*`m'*sqrt(-`m')))* 	(asin((2*`m'+`n')/`r') - asin(`n'/`r')) ;
		};
		else {;
			local gini_tt = (`e'/2)- `n'*(`b'+2)/(4*`m') - ((`r'^2)/(8*`m'*sqrt(`m')))
			*ln(abs(((2*`m')+`n'+(2*(sqrt(`m'))*(`a'+`c'-1)))/(`n'-(2*`e'*sqrt(`m')))));
		};
		#delim cr

		/*** Gini */
		local gini_ln = (2*normal(`lnsd'/sqrt(2))) - 1
		local lnsd_tt = sqrt(2)*invnormal((`gini_tt'+1)/2)
		local dirsigma = normal((1/`lnsd')*ln(`z'/`mu')+(`lnsd'/2))
		local ginisigma = normal((1/`lnsd_tt')*ln(`z'/`mu')+(`lnsd_tt'/2))
		local pglnd = `dirsigma' *((`z' - (normal((1/`lnsd')*ln(`z'/`mu')-(`lnsd'/2))* `mu' )/`dirsigma')/`z')
		local pglng = `ginisigma' * ((`z' - (normal((1/`lnsd_tt')*ln(`z'/`mu')-(`lnsd_tt'/2))* `mu' )/`ginisigma')/`z')
		local spglnd = `pglnd'*`pglnd'/`dirsigma'
		local spglng = `pglng'*`pglng'/`ginisigma'

		if "`gini_G'" !=""{
			local gini_gg=`gini_G'/100
			local lnsd_gg = sqrt(2)*invnormal((`gini_gg'+1)/2)
			local HcGg = normal((1/`lnsd_gg')*ln(`z'/`mu')+(`lnsd_gg'/2))
			local PgGg = (`z' - (normal((1/`lnsd_gg')*ln(`z'/`mu')-(`lnsd_gg'/2))* `mu' )/`HcGg')/`z'
			local SPgGg = `PgGg'*`PgGg'
		}

		if "`nsmean'" != "" {
			local tem3 = (1/`lnsd')*(ln(`z'/`nmu'))+(`lnsd'/2)
			local tem4 = (1/`lnsd1')*(ln(`z'/`nmu'))+(`lnsd1'/2)
			local dis12 = normal(`tem3')
			local dis13 = normal(`tem4')
		}

		if "`npovline'" != "" & "`nsmean'" != "" {
			local tem5 = (1/`lnsd')*(ln(`n'*`z'/`nmu'))+(lnsd/2)
			local tem6 = (1/`lnsd1')*(ln(`n'*`z'/`nmu'))+(lnsd1/2)
			local dis14 = normal(`tem5')
			local dis15 = normal(`tem6')
		}

		/*** Elasticities QG Lorenz */
		local elhmu         = -(`z'/(`mu'*`H'*`ldph'))
		local elhgini       = (1-(`z'/`mu'))/ (`H'*`ldph')
		local elpgmu        = 1-(`H'/`PG')
		local elpggini      = 1+(((`mu'/`z')-1)* (`H'/`PG'))
		local elspgmu       = 2*(1-`PG'/`SPG')
		local elspggini     = 2*(1+((`mu'/`z')-1)*(`PG'/`SPG'))

	*-----------------------------------------------------------------------------
	* 		Beta Lorenz Curve
	*-----------------------------------------------------------------------------

		`noidebug' di as text "Analytical calculations: Beta Lorenz Curve"

		if ("`coefb'" == "") {
			if ("`grouped'" != "") {
				local aatheta   =   exp(`cofbg'[1,3])
				local aagama    =   `cofbg'[1,1]
				local aagama2   =   2*`aagama'
				local aadelta   =   `cofbg'[1,2]
				local aadelta2  =   2*`aadelta'
			}
			else {
				local aatheta   =   exp(`cofb'[1,3])
				local aagama    =   `cofb'[1,1]
				local aagama2   =   2*`aagama'
				local aadelta   =   `cofb'[1,2]
				local aadelta2  =   2*`aadelta'
			}
		}
		if ("`coefb'" != "") {
				local aatheta   =   exp(real(trim(word("`coefb'",3))))
				local aagama    =   real(trim(word("`coefb'",1)))
				local aagama2   =   2*`aagama'
				local aadelta   =   real(trim(word("`coefb'",2)))
				local aadelta2  =   2*`aadelta'
		}
		
		/*** Poverty */

		local Xx=.00001*(1-`z'/`mu')

		local hcrb0 = .01
		local j = 1
		local ff=`aatheta'*`hcrb0'^`aagama'*(1-`hcrb0')^`aadelta'*((`aagama'/`hcrb0')-(`aadelta'/(1-`hcrb0')))-1+`z'/`mu'
		while ( `Xx' <`ff' | `ff' < -`Xx') & `j'<51 {
			local i=1
			local hcrb1 = 0
			local hcrb2 = `hcrb0'
			local ff1=`aatheta'*`hcrb2'^`aagama'*(1-`hcrb2')^`aadelta'*((`aagama'/`hcrb2')-(`aadelta'/(1-`hcrb2')))-1+`z'/`mu'

			while `hcrb2'-`hcrb1'>.0001 & `i'<500 {
				local ff2=`aatheta'*`hcrb2'^`aagama'*(1-`hcrb2')^`aadelta'*(`aagama'*(`aagama'-1) /*
				*// `hcrb2'^2-2*`aagama'*`aadelta'/(`hcrb2'*(1-`hcrb2'))+`aadelta'*(`aadelta'-1)/(1-`hcrb2')^2)
				local hcrb1=`hcrb2'
				local hcrb2 = `hcrb2' - (`ff1'/`ff2')
				local ff1=`aatheta'*`hcrb2'^`aagama'*(1-`hcrb2')^`aadelta'*((`aagama'/`hcrb2')-(`aadelta'/(1-`hcrb2')))-1+`z'/`mu'
				local i =`i'+1
			}
			local ff = `ff1'
			local hcrb0 = `hcrb0' + .01
			local j = `j'+1
		}
		local ff =`ff'
		local hcrb = `hcrb2'

		if abs(`ff')> `Xx' {
			local hcrb4=.0001
			local hcrb3 = .0001
			local j=1
			local fff=`aatheta'*`hcrb3'^`aagama'*(1-`hcrb3')^`aadelta'*((`aagama'/`hcrb3')-(`aadelta'/(1-`hcrb3')))-1+`z'/`mu'

		  while abs(`fff')>`Xx' & `j'<10000 {
				local hcrb3 = `hcrb3'+.0001
				local j = `j'+ 1
				local fff1=`aatheta'*`hcrb3'^`aagama'*(1-`hcrb3')^`aadelta'*((`aagama'/`hcrb3')-(`aadelta'/(1-`hcrb3')))-1+`z'/`mu'
				if abs(`fff1')>abs(`fff') {
					local fff = `fff'
				}
				else {
					local fff =`fff1'
					local hcrb4=`hcrb3'
				}
		  }
			local hcrb=`hcrb4'
			local ff =`ff1'
		}

		local LhBeta= `hcrb' - `aatheta'* `hcrb'^`aagama'*(1- `hcrb')^`aadelta'
		 local muDiz = `mu'/`z'

	  /*** Poverty Gap (Beta Lorenz) */
		 local PgBeta = `hcrb' - `muDiz'*`LhBeta'

		  /*** Poverty Gap Saqured (Beta Lorenz) */
		  local ibita1 = (ibeta(`aagama2'-1,`aadelta2'+1,`hcrb'))*exp(lngamma(`aagama2'-1))*exp(lngamma(`aadelta2'/*
		  */+1))/exp(lngamma(`aagama2'+`aadelta2'))
		  local ibita2 = (ibeta(`aagama2',`aadelta2',`hcrb'))*exp(lngamma(`aagama2'))*exp(lngamma(`aadelta2'/*
		  */))/exp(lngamma(`aagama2'+`aadelta2'))
		  local ibita3 = (ibeta(`aagama2'+1,`aadelta2'-1,`hcrb'))*exp(lngamma(`aagama2'+1))*exp(lngamma(`aadelta2'/*
		  */-1))/exp(lngamma(`aagama2'+`aadelta2'))

		  local FgtBeta = (1-`muDiz')*(2*`PgBeta'-(1-`muDiz')*`hcrb')+ `aatheta'*`aatheta'*`muDiz'*`muDiz'*((`aagama'*`aagama'*`ibita1')-/*
		  */2*`aagama'*`aadelta'*`ibita2' + `aadelta'*`aadelta'*`ibita3')

		  /*** Gini (Beta Lorenz) */
		  local GiniBeta = 2*`aatheta'*exp(lngamma(1+`aagama'))*exp(lngamma(1+`aadelta'))/exp(lngamma /*
		  */(2+`aagama'+`aadelta'))

		  local ldpBeta = `aatheta'*`hcrb'^`aagama'*(1-`hcrb')^`aadelta'*((`aagama'*(1-`aagama')/`hcrb'*`hcrb')+(2*`aagama'*`aadelta'/*
		  *//(`hcrb'*(1-`hcrb')))+(`aadelta'*(1-`aadelta')/((1-`hcrb')*(1-`hcrb'))))

		  /*** Elasticities (Beta Lorenz) */
		  local elhmub       = -(`z'/(`mu'*`hcrb'*`ldpBeta'))
		  local elhginib     = (1-(`z'/`mu'))/ (`hcrb'*`ldpBeta')
		  local elpgmub      = 1-(`hcrb'/`PgBeta')
		  local elpgginib    = 1+(((`mu'/`z')-1)* (`hcrb'/`PgBeta'))
		  local elspgmub     = 2*(1-`PgBeta'/`FgtBeta')
		  local elspgginib   = 2*(1+((`mu'/`z')-1)*(`PgBeta'/`FgtBeta'))

		if (`ibita3' == . ) {
		  local FgtBeta     = -.99
		  local elspgmub    = -99
		  local elspgginib  = -99
		  noi dis "WARNING: ibita3 in the Beta Loren Specification can not be computed"
		}

	*-----------------------------------------------------------------------------
	* Checking for consistency of GQ Lorenz Curve  estimation
	*-----------------------------------------------------------------------------

		/** Condition 1 : L(0;pi)=0*/
		if (`e' < 0) {
			local ccheck1 = 1
		}
		else {
			local ccheck1 = 0
		}

		/** Condition 2 : L(1;pi)=1*/
		local t = (`a'+`c')
		if (`t' >= 1) {
			local ccheck2 = 1
		}
		else {
			local ccheck2 = 0
		}

		/** Condition 3 : L'(0+;pi)>=0*/
		if (`c' >= 0) {
			local ccheck3 = 1
		}
		else {
			local ccheck3 = 0
		}

		/** Condition 4 : L''(p;pi)>=0 for p within (0,1)*/
		if ( `m' < 0 | (( 0 < `m' <(`n'^2/(4*`e'^2)))	& `n' >= 0) | ((0 < `m' < (-`n'/2)) & (`m' < (`n'^2 /(4*`e'^2))))) {
			local ccheck4 = 1
		}
		else {
			local ccheck4 = 0
		}

		*-----------------------------------------------------------------------------
		* Checking for consistency of Beta lorenz curve estimation
		*-----------------------------------------------------------------------------

		/** Condition 1 : L(0;pi)=0 */
		* automatically satisfied by the functional form
		* `nocheck' di as text "L(0;pi)=0: " as res "OK (automatically satisfied by the functional form)"

		/** Condition 2 : L(1;pi)=1 */
		* automatically satisfied by the functional form
		*`nocheck' di as text "L(1;pi)=1: " as res "OK (automatically satisfied by the functional form)"

		/** Condition 3 : "L'(0+;pi)>=0 */
		  * We check the validity of the Beta Lorenz curve
		local check1 = 1- `aatheta'*.001^`aagama'*.999^`aadelta'*(`aagama'/.001-`aadelta'/.999)
		if (`check1'>=0)  {
		  local bcheck3 = 1
		}
		else {
		  local bcheck3 = 0
		}
	  /** Condition 4 : L''(p;pi)>=0 for p within (0,1)*/

		local check2 = 0
		local i=.01
		while `i'<1 {
		  local chk = `aatheta'*`i'^`aagama'*(1-`i')^`aadelta'*((`aagama'*(1-`aagama')/`i'^2)+(2*`aagama'*`aadelta'/*
		  *//(`i'*(1-`i')))+(`aadelta'*(1-`aadelta')/(1-`i')^2))
		  if `chk'<0 {
			local check2=1
		  }
		  else {
		  }
		  local i=`i'+.01
		}

		if (`check2'==0) {
		  local bcheck4 = 1
		}
		else {
		  local bcheck4 = 0
		}

	*-----------------------------------------------------------------------------
	 * 	Output dataset
	*-----------------------------------------------------------------------------

		  `noidebug' di as text "Store results"

		  tempvar pline seq bin mean stdev seqpov seqmean

		  local Npline = wordcount("`zl'")

		  `noidebug' di "`pl'"

		  /*** Display results */

		  cap: gen `pline'   = ""
		  cap: gen `seq'     = .
		  cap: gen `type2'   = .
		  cap: gen `model'   = .
		  cap: gen `var'     = .
		  cap: gen `value'   = .
		  cap: gen `bin'     = .
		  cap: gen `mean'    = .
		  cap: gen `stdev'   = .
		  cap: gen `seqpov'    = .
		  cap: gen `seqmean'   = .
		  

		  cap: replace `pline'   = ""
		  cap: replace `seq'     = .
		  cap: replace `type2'   = .
		  cap: replace `model'   = .
		  cap: replace `var'     = .
		  cap: replace `value'   = .
		  cap: replace `bin'     = .
		  cap: replace `mean'    = .
		  cap: replace `stdev'    = .
		  cap: replace `seqpov'    = .
		  cap: replace `seqmean'   = .

		  replace `pline' = "Poverty line: `z'"
		  replace `seq'   = `z'
		  replace `mean'   = `mu'
		  replace `stdev'  = `sd'
		  replace `var'   = _n in 1/32
		  replace `bin'   = `bins'
		  replace `seqpov'   	= `ppp'
		  replace `seqmean'   	= `mmm'

		* main results type = 1
		   replace `type2'  = 1     in 1/8

		*elasticities lines (type=2 and type=3)
		  replace `type2'  = 2     	in  9
		  replace `type2'  = 3     	in  10
		  replace `type2'  = 2     	in  11
		  replace `type2'  = 3     	in  12
		  replace `type2'  = 2     	in  13
		  replace `type2'  = 3     	in  14
		  replace `type2'  = 2     	in  15
		  replace `type2'  = 3     	in  16
		  replace `type2'  = 2     	in  17
		  replace `type2'  = 3     	in  18
		  replace `type2'  = 2     	in  19
		  replace `type2'  = 3     	in  20

		  replace `type2'  = 4      in 25/32

		* model types
		  replace `model' = 	1   	  in 1/4
		  replace `model' = 	1     	in 9/14
		  replace `model' = 	2     	in 5/8
		  replace `model' = 	2     	in 15/20

		  replace `model' = 	1   	  in 25/28
		  replace `model' = 	2     	in 29/32


		* main results values
		  replace `value' = `H'*100               in  1
		  replace `value' = `PG'*100              in  2
		  replace `value' = `SPG'*100             in  3
		  replace `value' = `gini_ln'             in  4
		  replace `value' = `hcrb'*100            in  5
		  replace `value' = `PgBeta'*100          in  6
		  replace `value' = `FgtBeta'*100         in  7
		  replace `value' = `GiniBeta'            in  8

		* elasticities
		  replace `value' = `elhmu'               in  9
		  replace `value' = `elhgini'             in  10
		  replace `value' = `elpgmu'              in  11
		  replace `value' = `elpggini'            in  12
		  replace `value' = `elspgmu'             in  13
		  replace `value' = `elspggini'           in  14
		  replace `value' = `elhmub'              in  15
		  replace `value' = `elhginib'            in  16
		  replace `value' = `elpgmub'             in  17
		  replace `value' = `elpgginib'           in  18
		  replace `value' = `elspgmub'            in  19
		  replace `value' = `elspgginib'          in  20

		* output label
		  replace `var' = 1       in  1
		  replace `var' = 2       in  2
		  replace `var' = 3       in  3
		  replace `var' = 4       in  4
		  replace `var' = 1       in  5
		  replace `var' = 2       in  6
		  replace `var' = 3       in  7
		  replace `var' = 4       in  8
		  replace `var' = 1       in  9
		  replace `var' = 1       in  10
		  replace `var' = 2       in  11
		  replace `var' = 2       in  12
		  replace `var' = 3       in  13
		  replace `var' = 3       in  14
		  replace `var' = 1       in  15
		  replace `var' = 1       in  16
		  replace `var' = 2       in  17
		  replace `var' = 2       in  18
		  replace `var' = 3       in  19
		  replace `var' = 3       in  20

		  if ("`benchmark'" == "benchmark") {
				* add apoverty and ainequal to main results (type=1)
				replace `type2'	=	1 		       in 21/24
				* add apoverty and ainequal model (model=0)
				replace `model'	=	0		         in 21/24
				* add apoverty and ainequal values
				replace `value' = ``pl'afgt0'  in  21
				replace `value' = ``pl'afgt1'  in  22
				replace `value' = ``pl'afgt2'  in  23
				replace `value' = ``pl'agini'  in  24
				* add output label
				replace `var' = 1       in  21
				replace `var' = 2       in  22
				replace `var' = 3       in  23
				replace `var' = 4       in  24
		  }

		  replace `var' = 5      in  25
		  replace `var' = 6      in  26
		  replace `var' = 7      in  27
		  replace `var' = 8      in  28
		  replace `var' = 5      in  29
		  replace `var' = 6      in  30
		  replace `var' = 7      in  31
		  replace `var' = 8      in  32

	  * checks
		  replace `value' = `ccheck1'  in 25
		  replace `value' = `ccheck2'  in 26
		  replace `value' = `ccheck3'  in 27
		  replace `value' = `ccheck4'  in 28

		  replace `value' = 1           in 29
		  replace `value' = 1           in 30
		  replace `value' = `bcheck3'   in 31
		  replace `value' = `bcheck4'   in 32

	  * labels
		  label define var 1 "FGT(0)" , add modify
		  label define var 2 "FGT(1)" , add modify
		  label define var 3 "FGT(2)" , add modify
		  label define var 4 "Gini"   , add modify

		  label define var 5  "L(0;pi)=0"                       , add modify
		  label define var 6  "L(1;pi)=1"                       , add modify
		  label define var 7  "L'(0+;pi)>=0"                    , add modify
		  label define var 8  "L''(p;pi)>=0 for p within (0,1)" , add modify

		  label define model 0 "Unit Record"                    , add modify
		  label define model 1 "QG Lorenz Curve"                , add modify
		  label define model 2 "Beta Lorenz Curve"              , add modify

		  label define type 1 "Estimated Value"                 , add modify
		  label define type 2 "with respect to the Mean"        , add modify
		  label define type 3 "with respect to the Gini"        , add modify
		  label define type 4 "Checking for consistency of lorenz curve estimation", add modify

		  label define value -99  "NA"  , add modify
		  label define value 1    "OK"  , add modify
		  label define value 0    "FAIL", add modify

		  label values `model'  model
		  label values `type2'  type
		  label values `var'    var
		  label values `value'  value

		  label var `model' Model
		  label var `type2' Type
		  label var `var'   Indicator

	*-----------------------------------------------------------------------------
	* Display Lorenz
	*-----------------------------------------------------------------------------
		
		`noidebug' di as text "Display results"

		if (`skip' != 1) {
			
			label var `pg' p
			label var `Lg' Lorenz

			format `pg' %16.2f
			format `Lg' %16.3f

			`noilor' di 			""
			`noilor' di as text 	"{hline 15}    Distribution    {hline 15}"
			`noilor' di as text 	_col(5) "i "    _col(15) "P"   _col(40) "L"
			`noilor' di as text 	"{hline 50}"

			forvalues l = 1(1)`bins' {
				local P = `pg' in `l'
				local L = `Lg' in `l'
				`noilor' di as text _col(5) "`l'"  as res  _col(15) %5.4f `P'   _col(40) %5.4f `L'
			}

			`noilor' di as text 	"{hline 50}"

		}
		
	*-----------------------------------------------------------------------------
	* Display Regression results
	*-----------------------------------------------------------------------------

	if (`skip' != 1) {
		
	
		if ("`grouped'" == "grouped") {

		`noireg' di ""
			`noireg' di ""
		`noireg' di as text "Estimation: " as res "GQ Lorenz Curve (grouped data)"
		`noireg' estout  coefgqg, cells("b(star fmt(%9.3f)) se t p")                ///
				  stats(r2_a F rmse mss rss N, fmt(%9.3f %9.0g) labels("Adj. R-squared"))      ///
				  legend label

			`noireg' di ""
		`noireg' di ""
		`noireg' di as text "Estimation: " as res "Beta Lorenz Curve (Grouped data)"
			`noireg' estout coefbetag, cells("b(star fmt(%9.3f)) se t p")                ///
				  stats(r2_a F rmse mss rss N, fmt(%9.3f %9.0g) labels("Adj. R-squared" F-sta RMSE MSS RSS Obs))      ///
				  legend label  varlabels(_cons A)

		}

		if ("`grouped'" == "") {

			`noireg' di ""
		`noireg' di ""
		`noireg' di as text "Estimation: " as res "GQ Lorenz Curve"
			`noireg' estout  coefgq, cells("b(star fmt(%9.3f)) se t p")                ///
				  stats(r2_a F rmse mss rss N, fmt(%9.3f %9.0g) labels("Adj. R-squared" F-sta RMSE MSS RSS Obs))      ///
				  legend label

			`noireg' di ""
		`noireg' di ""
		`noireg' di as text "Estimation: " as res "Beta Lorenz Curve"
			`noireg' estout coefbeta, cells("b(star fmt(%9.3f)) se t p")                ///
				  stats(r2_a F rmse mss rss N, fmt(%9.3f %9.0g) labels("Adj. R-squared" F-sta RMSE MSS RSS Obs))      ///
				  legend label  varlabels(_cons A)

		}
	}

	*-----------------------------------------------------------------------------
	* Display Poverty and Inequality Results
	*-----------------------------------------------------------------------------

		noi di ""
		noi di ""
		noi di as text "Estimated Poverty and Inequality Measures:"
		noi tabdisp `var' `model' if `var' != . & `type2' == 1, cell(`value')
		noi di as text "Mean `inc':" _col(15) as res %16.2f `mu'
		noi di as text "Threshold:" _col(15) as res %16.2f `z'

	*-----------------------------------------------------------------------------
	* Display Elasticities
	*-----------------------------------------------------------------------------


		`noelast' di ""
	  `noelast' di ""
	  `noelast' di as text "Estimated Elasticities:"
	  `noelast' tabdisp `var' `model' `type2' if `var' != . & `type2' != 1 & `type2' != 4 & `value' != . , cell(`value')


	*-----------------------------------------------------------------------------
	*  Checking for consistency of lorenz curve estimation (section 4)
	*-----------------------------------------------------------------------------

		***********************
		/* GQ Lorenz Curve */
		***********************

		`nocheck' di as text "Estimation Validity"


		`nocheck' di ""
		`nocheck' di ""
		`nocheck' di as text "Checking for consistency of lorenz curve estimation: " as res "GQ Lorenz Curve"

		/** Condition 1 */
		if (`ccheck1' == 1) {
			`nocheck' di as text "L(0;pi)=0: " as res  "OK"
		}
		else {
			`nocheck' di as text "L(0;pi)=0: " as err "FAIL"
		}

		/** Condition 2 */
		local t = (`a'+`c')
		if (`ccheck2' == 1) {
			`nocheck' di as text "L(1;pi)=1: " as res "OK (value=" %9.4f `t' ")"
		}
		else {
			`nocheck' di as text "L(1;pi)=1: " as err "FAIL (value=" %9.4f `t' ")"
		}

		/** Condition 3 */
		if (`ccheck3' == 1) {
			`nocheck' di as text "L'(0+;pi)>=0: " as res  "OK"
		}
		else {
			`nocheck' di as text "L'(0+;pi)>=0: " as err "FAIL"
		}


		/** Condition 4 */

		if (`ccheck4' == 1) {
			`nocheck' di as text "L''(p;pi)>=0 for p within (0,1): " as res  "OK"
		}
		else {
			`nocheck' di as text "L''(p;pi)>=0 for p within (0,1): " as err "FAIL"
		}

		***********************
		/* Beta Lorenz curve */
		***********************

		`nocheck' di ""
		`nocheck' di as text "Checking for consistency of lorenz curve estimation: " as res "Beta Lorenz curve"

		/** Condition 1 */
		* automatically satisfied by the functional form
		`nocheck' di as text "L(0;pi)=0: " as res "OK (automatically satisfied by the functional form)"

		/** Condition 2 */
		* automatically satisfied by the functional form
		`nocheck' di as text "L(1;pi)=1: " as res "OK (automatically satisfied by the functional form)"

		/** Condition 3 */
			* We check the validity of the Beta Lorenz curve
		if (`bcheck3' == 1) {
		  `nocheck' di as text "L'(0+;pi)>=0: " as res  "OK"
		}
		else {
		  `nocheck' di as text "L'(0+;pi)>=0: " as err "FAIL "
			 }

		/** Condition 4 */
		if (`bcheck4'==0) {
		  `nocheck' di as text "L''(p;pi)>=0 for p within (0,1): " as res  "OK"
		}
		else {
		  `nocheck' di as text "L''(p;pi)>=0 for p within (0,1): " as err "FAIL"
		}
		`nocheck' di as text ""
		`nocheck' di as text ""



	*-----------------------------------------------------------------------------
	* Store results
	*-----------------------------------------------------------------------------

		`noidebug' di as text "Return results"

		tempname tmp`pl'

			mkmat  `seq' `seqpov'  `seqmean'  `mean' `stdev' `var' `model' `type2' `value' if `value' != . , matrix(`tmp`pl'')

			matrix colnames `tmp`pl'' = povline seqpov seqmean mean sd indicator model type value

			mat check = `tmp`pl''

		matrix rownames `tmp`pl'' = H  PG  SPG  gini_ln  hcrb  PgBeta	 FgtBeta	 GiniBeta   ///
		  elhmu	  elhgini 	elpgmu	 elpggini	 elspgmu	 elspggini	 elhmub	                ///
		  elhginib	 elpgmub	 elpgginib	 elspgmub	 elspgginib                             ///
		  `rownames_unitrecord'                                                             ///
		  check1qg check2qg check2qg check2qg                                               ///
		  check1b check2b check2b check2b


		mat `rtmp' = nullmat(`rtmp') \ `tmp`pl''

		return scalar Hgq   		  = `H'*100
		return scalar PGgq  		  = `PG'*100
		return scalar SPGgq 		  = `SPG'*100
		return scalar GINIgq  		= `gini_ln'
		return scalar Hb    		  = `hcrb'*100
		return scalar PGb   		  = `PgBeta'*100
		return scalar SPGb  		  = `FgtBeta'*100
		return scalar GINIb 		  = `GiniBeta'
		return scalar elhmu       = `elhmu'
		return scalar elhgini     = `elhgini'
		return scalar elpgmu      = `elpgmu'
		return scalar elpggini    = `elpggini'
		return scalar elspgmu     = `elspgmu'
		return scalar elspggini   = `elspggini'
		return scalar elhmub      = `elhmub'
		return scalar elhginib    = `elhginib'
		return scalar elpgmub     = `elpgmub'
		return scalar elpgginib   = `elpgginib'
		return scalar elspgmub    = `elspgmub'
		return scalar elspgginib  = `elspgginib'

		if ("`grouped'" != "") {
			return scalar agq = `a'
			return scalar bgq = `b'
			return scalar cgq = `c'
		}
		if ("`grouped'" == "") {
		  return scalar agq = `a'
		  return scalar bgq = `b'
		  return scalar cgq = `c'
		}

		if ("`grouped'" != "") {
		   return scalar theta   =   `aatheta'
		   return scalar gama    =   `aagama'
		   return scalar delta   =   `aadelta'
		}
		if ("`grouped'" == "") {
		   return scalar theta   =   `aatheta'
		   return scalar gama    =   `aagama'
		   return scalar delta   =   `aadelta'
		}

		if ("`nochecks'" != "") {
		  return scalar check1b   	= 1
		  return scalar check2b   	= 1
		  return scalar check3b   	= `bcheck3'
		  return scalar check4b   	= `bcheck4'
		  return scalar check1gq  	= `ccheck1'
		  return scalar check2gq  	= `ccheck2'
		  return scalar check3gq  	= `ccheck3'
		  return scalar check4gq  	= `ccheck4'
		  return scalar t         	= `t'
		}

		return scalar mu        	= `mu'
		return scalar sd			= `sd'
		return scalar z`pl'       = `z'

		local mmm = `mmm' + 1

	}

	local ppp = `ppp' + 1

	return local  zlines  "`zl'"
	return scalar zl      = `Npline'
	return matrix results = `rtmp'
	  
  }
  
  restore

  return add

 }

end


********************************************************************************
* cleanversion ado
*! v 1.0  4apr2020              by  JPA cleanversion
********************************************************************************

cap: program drop cleanversion
program define cleanversion, rclass

	version 8.0

	syntax , input(string) lookfor(string) [keep(string)]

		local _length 	= length("`input'")
		local maxi    	= `_length'
		local _count 	= 0

		local x = strpos("`input'","`lookfor'")

		local prefix 	= substr("`input'",1,`x')

		local sufix 	= subinstr(subinstr("`input'","`prefix'","",.), "." , "", .)

		local output	= `prefix'`sufix'

    return scalar result1 = `output'
    return local  result2 =	"`prefix'`sufix'"

end
