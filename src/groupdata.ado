*-----------------------------------------------------------------------------
*! v3.4 01Aug2026             by  JPA		groupdata
*   fix option validation (type, coef, bins), the grouped-data range
*   qualifiers that aborted type(2)/type(5)/type(6), the type(5) fweight
*   Lorenz share, Lorenz consistency checks, figure reference lines, sd()
*   handling, and RNG state preservation.
*   See version history at the end of this file.
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
				multiple		///
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
* 	Filters
*-----------------------------------------------------------------------------

	tokenize `varlist'
	local inc `1'
	mark `touse' `if' `in' [`weight'`exp']
	* remove missing values from estimates
	markout `touse'  `varlist'
	* number of observations used in the estimation
	count if `touse'
	local Nobs = r(N)

*-----------------------------------------------------------------------------
* 	Data sort
*-----------------------------------------------------------------------------

	* preserve the caller's random-number generator state
	local rngstate "`c(rngstate)'"
	set seed 1234568
	gen double `rnd' = runiform()		if `touse'
	gen `lninc' 	= ln(`inc') 		if `touse'
	gen `lnmpce' 	= ln(`inc') 		if `touse'
	sort `inc' `rnd'
	* restore the caller's random-number generator state
	set rngstate `rngstate'
	
*-----------------------------------------------------------------------------
* Set default values
*-----------------------------------------------------------------------------

  * keep track of whether the user supplied the sd() option
  local sdint = `sd'

  * first poverty line, used as reference line in the figures
  local zfirst : word 1 of `zl'

  * set default value for the mean
  if ("`mean'" == "") {
		local meanint "-99"
		* generate mean and standard deviation for unit record data
		sum `inc' [`weight'`exp']		if `touse'
		local mu = `r(mean)'
		if (`sdint' == -99) {
			local sd = `r(sd)'
		}
  }
  if ("`mean'" != "") {
		local meanint "`mean'"
		if (wordcount("`mean'") == 1) {
			local mu = `meanint'
		}
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
	if inlist("`type'","1","2","5","6") & ("`grouped'" != "") {
		noi di ""
		di as err "Option type() cannot be combined with the grouped option; type() describes grouped data provided by the user."
		exit 198
	}
	if inlist("`type'","1","2","5","6") & ("`binvar'" == "") & ("`grouped'" == "") & (("`coefgq'" == "") | ("`coefb'" == "")) {
		noi di ""
		di as err "Please make sure you specified the binvar option."
		exit 198
	}

	if ("`type'" != "") & !inlist("`type'","1","2","5","6") {
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
	if (("`coefb'" != "") | ("`coefgq'" != "")) & ("`type'" == "") & ("`grouped'" == "") {
		if ("`coefb'" == "") {
			noi di ""
			di as err "Both vectors of coefficients must be specified. see help."
			exit 198
		}
		if ("`coefgq'" == "") {
			noi di ""
			di as err "Both vectors of coefficients must be specified. see help."
			exit 198
		}
		local skip = 1
		local type = -88
	}

	* check the bins option
	if ("`grouped'" != "") & (`bins' != -99) & (`bins' < 4) {
		noi di ""
		di as err "Option bins() must specify at least 4 bins."
		exit 198
	}

	* one of the estimation modes must be selected
	if ("`type'" == "") & ("`grouped'" == "") & ("`unitrecord'" == "") & ("`coefb'" == "") & ("`coefgq'" == "") {
		noi di ""
		di as err "Please select an estimation mode: grouped, unitrecord, type(), or coefb()/coefgq()."
		exit 198
	}

	* unitrecord fits the parametric Lorenz curves to the raw unit records rather
	* than to bins, and the fit is not usable. Measured on qa/score2017.dta
	* (grade 5, z=200): the GQ fit is degenerate -- e = +0.0005 violates L(0)=0,
	* the discriminant goes negative, every GQ quantity is missing -- and the
	* Beta fit returns a headcount of 1.49 against a microdata headcount of
	* 39.28. Under other restrictions it returns worse: a negative headcount.
	*
	* The consistency checks do fire here -- GQ reports 0 0 0 0 and Beta 1 1 1 0
	* -- but they cannot be relied on to flag it: check1b and check2b are
	* hardcoded to 1 (see the writes in 29/30 and the returns below), because
	* the Beta functional form satisfies conditions 1 and 2 by construction. So
	* two of the four Beta checks can never fail whatever the fit does, and with
	* nochecks nothing is reported at all.
	*
	* Refused rather than returning numbers that look plausible. Note the guard
	* is on grouped alone: unitrecord with type() is NOT a working combination
	* either -- both blocks gen the same tempvars (`y1' `a' `b' `c' ...) so it
	* aborts with r(110), on this branch and before it. Refusing turns that
	* cryptic collision into the actionable message below.
	* The coefficient path is caught by the same guard and gets its own message:
	* it does not set grouped, and it never ran the unitrecord block at all (the
	* skip block spanning the estimation code excludes it), so unitrecord there
	* was a silent no-op returning the coef path's own numbers -- measured
	* byte-identical with and without the option.
	if ("`unitrecord'" != "") & ("`grouped'" == "") {
		if (`skip' == 1) {
			noi di ""
			di as err "Option unitrecord cannot be combined with coefb()/coefgq():"
			di as err "the coefficient vectors already determine the Lorenz curves, so"
			di as err "unitrecord would have no effect. Drop one of them."
			exit 198
		}
		noi di ""
		di as err "Option unitrecord requires grouped: fitting the parametric Lorenz"
		di as err "curves to raw unit records does not converge to a usable curve."
		di as err "Use grouped to build bins from the same unit records, or estimate"
		di as err "directly from the microdata with apoverty and ainequal."
		exit 198
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
			local weight2 = "fweight"
			local pop "`wtg'"
		}
		else {
			local pop =subinstr("`exp'","=","",.)
	  }
		
	*-----------------------------------------------------------------------------
	* checks with Type 1 is selected
		if ("`type'" == "1") {
		   if ("`wtg2'" == "") {
				noi di as err "Type 1 only accepts aweights."
				exit 198
			}
			if strmatch("pweight","*`wtg2'*") == 1 {
				noi di as err "Type 1 only accepts aweights."
				exit 198
			}
			if strmatch("fweight","*`wtg2'*") == 1 {
				noi di as err "Type 1 only accepts aweights."
				exit 198
			}
		}

	  *-----------------------------------------------------------------------------
	  * checks with Type 2 is selected
		if ("`type'" == "2") {
		if ("`wtg2'" == "") {
			noi di as err "Type 2 only accepts aweights."
			exit 198
		}
		if strmatch("pweight","*`wtg2'*") == 1 {
			noi di as err "Type 2 only accepts aweights."
			exit 198
		}
		if strmatch("fweight","*`wtg2'*") == 1 {
			noi di as err "Type 2 only accepts aweights."
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

	* install any missing user-written commands
		qui foreach command of local user_commands {
			cap which `command'
			if _rc == 111 {
				ssc install `command'
			}
		}

	* make sure the minimum required versions are installed
	* (cleanversion is defined at the bottom of this file, so it is always
	* available once groupdata.ado has been loaded)
		qui {
			* groupfunction >= 2.0
			cap which_version groupfunction
			if (_rc == 0) {
				cleanversion, input(`s(version)') lookfor(.)
				if (`r(result1)' < 2.0) {
					ado update groupfunction , update
				}
			}
			* alorenz >= 3.1
			cap which_version alorenz
			if (_rc == 0) {
				cleanversion, input(`s(version)') lookfor(.)
				if (`r(result1)' < 3.1) {
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
			loc noilor1 ""
		}
		else {
			loc noilor1 "noi"
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
			loc nocheck1 ""
		}
		else {
			loc nocheck1 "noi"
		}

		* debug
		if ("`debug'" == "") {
			loc noidebug 
		}
		else {
			loc noidebug noi:
		}

	*-----------------------------------------------------------------------------
	* 	Unit Record estimations used to benchmark results
	*-----------------------------------------------------------------------------

	  `noidebug' di as text "Unit Record estimations used to benchmark results"

	qui if ("`benchmark'" == "benchmark") {
		* create counter
		local ppp = 0
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
			local ppp = `ppp' + 1
		}
	}

	*-----------------------------------------------------------------------------
	* 	Estimate results using unit record
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

		`noidebug' sum `L' `p'  `y1' `a' `b' `c'  `y2' `x1' `x2' if `y1' !=. & `touse'
		`noidebug' list `L' `p'  `y1' `a' `b' `c'  `y2' `x1' `x2' if `y1' !=. & `touse'


		************************************
		** Estimation: GQ Lorenz Curve
		************************************
		`noidebug' di as text "Unit Record : Estimation: GQ Lorenz Curve"

			label var `y1' 	"`inc'"
			label var `a'  	"A"
			label var `b' 	"B"
			label var `c'	"C"

		`noidebug'  reg `y1' `a' `b' `c' in 1/`last' if `touse', noconstant
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

		`noidebug'  reg `y2' `x1' `x2' in 1/`last' if `touse'
		est store coefbeta
		mat `cofb' = e(b)

	  }

	*-----------------------------------------------------------------------------
	* Group data provided
	* Need to specify the Type of Group data provided
	*-----------------------------------------------------------------------------

	  qui if ("`type'" != "") {
	  
		noi di ""
		noi di "Grouped data provided..."

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
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1]       	in 2/`bins'
				gen `pg' = `exp2'/100						in 1/`bins'
				replace `pg' = `pg'[_n]+`pg'[_n-1]       	in 2/`bins'
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
				`noidebug' list  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse' if `pg' != .
				`noidebug' sum  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse'  if `pg' != .
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
				`noidebug' list  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse' if `pg' != .
			}


			if (substr(trim("`wtg2'"),1,2) == "fw") {
				sum `exp2'									in 1/`bins'
				local sumP = r(sum)
				gen double 	`pg' = `exp2'/`sumP'			in 1/`bins'
				replace `pg' = `pg'[_n]+`pg'[_n-1]       	in 2/`bins'
				sum `inc' 	[`weight'`exp']					in 1/`bins'
				local sumL = r(sum)
			  * sumL is population-weighted, so the numerator must be too
				gen double 	`Lg' = (`exp2'*`inc')/`sumL'	in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1]       	in 2/`bins'
				
				`noidebug' di as text "Type 5 grouped data"
				`noidebug' di as text `"(substr(trim("`wtg2'"),1,2) == "fw")"'
				`noidebug' list  `ccc' `binvar' `pg' `inc' `Lg' `LLLLL' `PPPPP' `touse' if `pg' != .
				`noidebug' di ""
			}
		}

	************************************
	** Type 6 grouped data: W=Percentage of the population in a given interval of incomes, X=The max income of that interval
	************************************

		tempvar inc2 delta
		if ("`type'" == "6") {
		  * mean welfare
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
				replace `delta' = (`inc'[_n]-`inc'[_n-1])	/2 					in 2/`last'
				replace `delta' = (`max'	-`inc'[_n-1])	/2 					in `bins'		
				replace `pg' = `pg'[_n]+`pg'[_n-1] 								in 2/`bins'						
				gen double `inc2' = .											
				replace `inc2' = `inc' - `delta'								in 1/`last'		
				replace `inc2' = `max' - `delta'								in `bins'		
				sum `inc2'														in 1/`bins'
				local sumL = r(sum)
				gen double 	`Lg' = `inc2'/`sumL'								in 1/`bins'
				replace `Lg' = `Lg'[_n]+`Lg'[_n-1]       						in 2/`bins'
				
				`noidebug' di as text "Type 6 grouped data: wtg2 == null"
				`noidebug' list `pg' `inc' `delta' `inc2' `Lg' 					if `pg' != .
				`noidebug' di ""
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
				
				`noidebug' di as text "Type 6 grouped data: wtg2 == pw"
				`noidebug' list `pg' `inc' `delta' `inc2' `Lg' 					if `pg' != .
				`noidebug' di ""
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

				`noidebug' di as text "Type 6 grouped data: wtg2 == fw"
				`noidebug' list `pg' `inc' `delta' `inc2' `Lg' 					if `pg' != .
				`noidebug' di ""
			}
		}

	  ************************************
	  ** Generate the cumulative distribution
	  ************************************

		sort `pg'
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
		** Plot Figures 1
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
				xline(`zfirst') xtitle("`inc'") name(pdf, replace)

			graph twoway lowess `inc' `p'	if `touse', 						///
				yline(`zfirst') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
				note("mean: `mustr' [`bins' bins]") name("pen", replace)
				
			`noidebug' di as text "Plot figure 1"
			`noidebug' sum  `L' `p' 	if `p' !=. 
			`noidebug' list `L' `p' 	if `p' !=. 
			`noidebug' list `L' `p' 	if `p' !=. 
			`noidebug' di ""

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
		** Plot Figures 2
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
				xline(`zfirst') xtitle("`inc'") name(pdf, replace)
			* figure 3 - Pen's parade
			graph twoway lowess `inc' `p'	, 						///
				yline(`zfirst') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
				note("mean: `mustr' [`bins' bins]") name("pen", replace)

			`noidebug' di as text "Plot figures 2"
			`noidebug' sum  `L' `p' 	if `p' !=. 
			`noidebug' list `L' `p' 	if `p' !=. 
			`noidebug' list `L' `p'  	if `p' !=. 
			`noidebug' list `Lg' `L' `pg' `p'  `y1' `a' `b' `c'  `y2' `x1' `x2' if `y1' !=. & `p' !=. 
			`noidebug' di ""

		}

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
	* Unit records are provided
	* Group data is estimated by alorenz.ado
	*-----------------------------------------------------------------------------
	
	  qui if ("`grouped'" == "grouped") {
			noi di ""
			noi di "Estimation using unit records, grouped data generated on the fly..."

		** cumulative distribution (grouped data)
		* if bins are not specified the default value is 20 bins
		if (`bins' == -99) {
			local bins = 20
		}
		noi di ""
		noi di "... creating grouped data with `bins' bins."
		noi di ""
		alorenz `inc' [`weight'`exp']	if `touse', points(`bins')
		
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

		`noidebug' di as text "Display groupdata produced by alorenz.ado"
		`noidebug' mat list r(lorenz1)
		`noidebug' sum  `A'2 `A'4 `Lg' `pg' `yg' `ag' `bg' `cg' `yg2' `x1g' `x2g' `touse'  if `pg' != .
		`noidebug' list `A'2 `A'4 `Lg' `pg' `yg' `ag' `bg' `cg' `yg2' `x1g' `x2g' `touse'  if `pg' != .
		`noidebug' di as text ""
		
	************************************
	** Plot Figure 3
	************************************

		if ("`nofigures'" == "") {

			local mustr = strofreal(`mu',"%9.2f")
			local intercept00 = `bins'+1
			
			replace `Lg' = 0 in `intercept00'
			replace `pg' = 0 in `intercept00'
			
			* Figure 1 - Lorenz
			graph twoway lowess `Lg' `pg', 									///
				ytitle("Lorenz") xtitle("Population (Cumulative)") 		    ///
				note("mean: `mustr' [`bins' bins]") name(lorenz, replace)
			* Figure 2 - PDF
			kdensity `A'6, 										       		///
				xline(`zfirst') xtitle("`inc'") name(pdf, replace)
			* Figure 3 - Pen's Parade
			graph twoway lowess `A'3 `pg', 							    		///
				yline(`zfirst') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
				note("mean: `mustr' [`bins' bins]") name("pen", replace)

			`noidebug' di as text "Plot figure 3"
			`noidebug' sum  `Lg' `pg'  	if `pg' != .
			`noidebug' list `Lg' `pg' 	if `pg' != .
			`noidebug' di as text ""

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
		label variable `x1g'    "B"
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

  * Moments of the estimation sample. These depend on neither the poverty line
  * nor the mean, and the loop below mutates the data in place (keep if
  * `pg' != .), so they must be measured once, here. Measuring them inside the
  * loop made every iteration after the first read the grouped bins instead of
  * the estimation sample: with multiple zl() the reported mean collapsed from
  * 214.28 to 92.06 and FGT(0) exceeded 100.
	sum `inc' [`weight2'`exp']			if `touse'
	local mu_s   = r(mean)
	sum `lnmpce' [`weight2'`exp']		if `touse'
	local lnmu_s = r(mean)
	local sd_s   = r(sd)

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
			* mean and standard deviation of the unit record data,
			* measured once before this loop
			  local mu   = `mu_s'
			local lnmu = `lnmu_s'
			if (`sdint' == -99) {
				local sd   = `sd_s'
			}
			local lnsd = ln(`sd')
		  }
		  if (`mu' != -99) {
			* use the mean provided as an option
			local lnmu = ln(`mu')
			if (`sdint' == -99) {
				local sd   = `sd_s'
			}
			local lnsd = ln(`sd')
		  }
		}

		* generate mean values for group data estimations
		if ("`type'" != "") {
		  * mean value is provided by the command as a parameters
		    local lnmu = ln(`mu')
			local mu = `mu'
			if (`sd' == -99) {
				local lnmu = ln(`mu')
				local sd   = `sd_s'
				local lnsd = ln(`sd')
			}
			if (`sd' != -99)  {
				local lnsd = ln(`sd')
			}
		}
			
		* Only grouped() and type() build the bin ordinates. Standalone
		* unitrecord has no bins, so there is nothing to keep and `pg' does
		* not exist -- guarding on skip alone made it exit with r(111).
		if (`skip' != 1) & (("`grouped'" != "") | ("`type'" != "")) {
			*keep only group data
			keep if `pg' != .
		}

		 * increase the number of rows to match what is required by
		 * output matrix (32 rows)
		local N = _N
		if (`N' < 32) {
			set obs 32
		}
	
	`noidebug' di as text "Display mean values computed"
	`noidebug' di as text "mean: `mu'"
	`noidebug' di as text "lnmu: `lnmu'"
	`noidebug' di as text ""

	
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
		* GQ Lorenz Gini (Datt 1998). Verified against this fixture: the value
		* below matches numerical integration of L(p) over [0,1] and the
		* microdata Gini from ainequal to four decimals. This is what
		* r(GINIgq) reports; before v3.3 it reported gini_ln instead.
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
		* Lognormal-approximation Gini, returned as r(GINIln). If welfare were
		* lognormal with log standard deviation s, its Gini would be
		* 2*Phi(s/sqrt(2))-1. `sd' already holds the standard deviation of log
		* welfare, so it is the s of that expression.
		* Until v3.3 this passed `lnsd' = ln(`sd') instead -- a double log -- and
		* the result was returned as r(GINIgq), mislabelled as the GQ Lorenz
		* Gini. On the QA fixture that gave -0.676 against a microdata Gini of
		* 0.134; the corrected expression gives 0.139.
		local gini_ln = (2*normal(`sd'/sqrt(2))) - 1
		local lnsd_tt = sqrt(2)*invnormal((`gini_tt'+1)/2)
		local dirsigma = normal((1/`lnsd')*ln(`z'/`mu')+(`lnsd'/2))
		local ginisigma = normal((1/`lnsd_tt')*ln(`z'/`mu')+(`lnsd_tt'/2))
		local pglnd = `dirsigma' *((`z' - (normal((1/`lnsd')*ln(`z'/`mu')-(`lnsd'/2))* `mu' )/`dirsigma')/`z')
		local pglng = `ginisigma' * ((`z' - (normal((1/`lnsd_tt')*ln(`z'/`mu')-(`lnsd_tt'/2))* `mu' )/`ginisigma')/`z')
		local spglnd = `pglnd'*`pglnd'/`dirsigma'
		local spglng = `pglng'*`pglng'/`ginisigma'


		/*** Elasticities GQ Lorenz */
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

		/* Solve equation (2), L'(H) = z/mu, for the Beta Lorenz headcount H.
		   Newton-Raphson from starting values H0 = .01, .02, ... (up to 50
		   starts, tolerance Xx, at most 500 iterations per start). If no
		   start converges, fall back to a grid search over H in (0,1) with
		   step .0001, keeping the H with the smallest residual. Convergence
		   is reported in r(bconverged). */
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

		* convergence diagnostic: residual of L'(H)-z/mu at the solution
		local ffinal = `aatheta'*`hcrb'^`aagama'*(1-`hcrb')^`aadelta'*((`aagama'/`hcrb')-(`aadelta'/(1-`hcrb')))-1+`z'/`mu'

		local LhBeta= `hcrb' - `aatheta'* `hcrb'^`aagama'*(1- `hcrb')^`aadelta'
		 local muDiz = `mu'/`z'

	  /*** Poverty Gap (Beta Lorenz) */
		 local PgBeta = `hcrb' - `muDiz'*`LhBeta'

		  /*** Poverty Gap Squared (Beta Lorenz) */
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
		  noi dis "WARNING: ibita3 in the Beta Lorenz specification cannot be computed"
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
		* Evaluate the fitted curve at p=1 and test the condition the label
		* claims. Until v3.3 this tested (a+c)>=1 and printed a+c beside the
		* label L(1;pi)=1, so a curve with a+c=1.2945 was reported as OK.
		local t = -(1/2)*(`b' + `e' + sqrt(`m' + `n' + (`e'*`e')))
		if (abs(`t' - 1) < 1e-6) {
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
		if ( (`m' < 0) | ((0 < `m') & (`m' < (`n'^2/(4*`e'^2))) & (`n' >= 0)) | ((0 < `m') & (`m' < (-`n'/2)) & (`m' < (`n'^2/(4*`e'^2)))) ) {
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

		/** Condition 3 : L'(0+;pi)>=0 */
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
		  replace `value' = `gini_tt'             in  4
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
		  label define model 1 "GQ Lorenz Curve"                , add modify
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
		
		`noidebug' di as text "Display Results"

		`noidebug' di as text "Display Lorenz"

		* Same guard: the distribution table is a grouped-data view.
		if (`skip' != 1) & (("`grouped'" != "") | ("`type'" != "")) {
			
			label var `pg' p
			label var `Lg' Lorenz

			format `pg' %16.2f
			format `Lg' %16.3f

			`noilor1' di 			""
			`noilor1' di as text 	"{hline 15}    Distribution    {hline 15}"
			`noilor1' di as text 	_col(5) "i "    _col(15) "P"   _col(40) "L"
			`noilor1' di as text 	"{hline 50}"
			
			* sort database by the cumulative probability
			sort `pg'
			
			* select only the number of observations in which value is different
			* from missing
			sum `pg'
			local binstrim = r(N) 
			
			forvalues l = 1(1)`binstrim' {
				local P = `pg' in `l'
				local L = `Lg' in `l'
				`noilor1' di as text _col(5) "`l'"  as res  _col(15) %5.4f `P'   _col(40) %5.4f `L'
			}
			
			`noilor1' di as text 	"{hline 50}"
			if (`bins'!=`binstrim') {
				noi di as res "Note: Intercept [0,0] added. " 
			}

			`noidebug' sum  `pg' `Lg' 
			`noidebug' list `pg' `Lg' if `pg' != .

		}
		
	*-----------------------------------------------------------------------------
	* Display Regression results
	*-----------------------------------------------------------------------------

	if (`skip' != 1) {
		
		`noidebug' di as text "Display Regression"
	
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

		`nocheck1' di as text "Estimation Validity"


		`nocheck1' di ""
		`nocheck1' di ""
		`nocheck1' di as text "Checking for consistency of lorenz curve estimation: " as res "GQ Lorenz Curve"

		/** Condition 1 */
		if (`ccheck1' == 1) {
			`nocheck1' di as text "L(0;pi)=0: " as res  "OK"
		}
		else {
			`nocheck1' di as text "L(0;pi)=0: " as err "FAIL"
		}

		/** Condition 2 */
		if (`ccheck2' == 1) {
			`nocheck1' di as text "L(1;pi)=1: " as res "OK (value=" %9.4f `t' ")"
		}
		else {
			`nocheck1' di as text "L(1;pi)=1: " as err "FAIL (value=" %9.4f `t' ")"
		}

		/** Condition 3 */
		if (`ccheck3' == 1) {
			`nocheck1' di as text "L'(0+;pi)>=0: " as res  "OK"
		}
		else {
			`nocheck1' di as text "L'(0+;pi)>=0: " as err "FAIL"
		}


		/** Condition 4 */

		if (`ccheck4' == 1) {
			`nocheck1' di as text "L''(p;pi)>=0 for p within (0,1): " as res  "OK"
		}
		else {
			`nocheck1' di as text "L''(p;pi)>=0 for p within (0,1): " as err "FAIL"
		}

		***********************
		/* Beta Lorenz curve */
		***********************

		`nocheck1' di ""
		`nocheck1' di as text "Checking for consistency of lorenz curve estimation: " as res "Beta Lorenz curve"

		/** Condition 1 */
		* automatically satisfied by the functional form
		`nocheck1' di as text "L(0;pi)=0: " as res "OK (automatically satisfied by the functional form)"

		/** Condition 2 */
		* automatically satisfied by the functional form
		`nocheck1' di as text "L(1;pi)=1: " as res "OK (automatically satisfied by the functional form)"

		/** Condition 3 */
			* We check the validity of the Beta Lorenz curve
		if (`bcheck3' == 1) {
		  `nocheck1' di as text "L'(0+;pi)>=0: " as res  "OK"
		}
		else {
		  `nocheck1' di as text "L'(0+;pi)>=0: " as err "FAIL "
			 }

		/** Condition 4 */
		if (`bcheck4'==1) {
		  `nocheck1' di as text "L''(p;pi)>=0 for p within (0,1): " as res  "OK"
		}
		else {
		  `nocheck1' di as text "L''(p;pi)>=0 for p within (0,1): " as err "FAIL"
		}
		`nocheck1' di as text ""
		`nocheck1' di as text ""



	*-----------------------------------------------------------------------------
	* Store results
	*-----------------------------------------------------------------------------

		`noidebug' di as text "Return results"

		tempname tmp`pl'

			mkmat  `seq' `seqpov'  `seqmean'  `mean' `stdev' `var' `model' `type2' `value' if `value' != . , matrix(`tmp`pl'')

			matrix colnames `tmp`pl'' = povline seqpov seqmean mean sd indicator model type value
		
		* Row names for the fixed 32-slot layout:
		*    1-8   GQ then Beta estimates
		*    9-20  elasticities (GQ then Beta)
		*   21-24  microdata benchmark, populated only by benchmark
		*   25-32  consistency checks
		* mkmat above keeps only the rows it finds non-missing, so the names are
		* selected the same way rather than listed as a fixed literal. A mode that
		* leaves some slots empty then still yields matching row and name counts.
		* Previously the list was fixed at 28 names (32 with benchmark), so any
		* mode populating a different number of slots died at this line with
		* r(503): standalone unitrecord fills 18 of 28, because fitting the GQ
		* Lorenz curve to raw unit records is degenerate here and leaves the whole
		* GQ half missing.
		local rowslots "H PG SPG GiniGQ hcrb PgBeta FgtBeta GiniBeta"
		local rowslots "`rowslots' elhmu elhgini elpgmu elpggini elspgmu elspggini"
		local rowslots "`rowslots' elhmub elhginib elpgmub elpgginib elspgmub elspgginib"
		local rowslots "`rowslots' fgt0 fgt1 fgt2 gini"
		local rowslots "`rowslots' check1gq check2gq check3gq check4gq"
		local rowslots "`rowslots' check1b check2b check3b check4b"

		local rownameslist ""
		local nslots : word count `rowslots'
		forvalues rowi = 1/`nslots' {
			if (`value'[`rowi'] != .) {
				local rownameslist "`rownameslist' `: word `rowi' of `rowslots''"
			}
		}
		matrix rownames `tmp`pl'' = `rownameslist'


			mat check = `tmp`pl''

	        mat check`pl' = `tmp`pl''

		mat `rtmp' = nullmat(`rtmp') \ `tmp`pl''

		if ("`multiple'" != "") {
			return scalar Hgq_`ppp'`mmm'		= `H'*100
			return scalar PGgq_`ppp'`mmm'	= `PG'*100
			return scalar SPGgq_`ppp'`mmm'	= `SPG'*100
			return scalar GINIgq_`ppp'`mmm'	= `gini_tt'
			return scalar GINIln_`ppp'`mmm'	= `gini_ln'
			return scalar Hb_`ppp'`mmm'		= `hcrb'*100
			return scalar PGb_`ppp'`mmm'		= `PgBeta'*100
			return scalar SPGb_`ppp'`mmm'	= `FgtBeta'*100
			return scalar GINIb_`ppp'`mmm'	= `GiniBeta'
			return scalar mu_`ppp'`mmm'     = `mu'
			return scalar z`pl'_`ppp'`mmm'  = `z'
		}

		return scalar Hgq   	  	= `H'*100
		return scalar PGgq  	  	= `PG'*100
		return scalar SPGgq 	  	= `SPG'*100
		return scalar GINIgq  	= `gini_tt'
		return scalar GINIln  	= `gini_ln'
		return scalar Hb    	= `hcrb'*100
		return scalar PGb   	  	= `PgBeta'*100
		return scalar SPGb  	 	 = `FgtBeta'*100
		return scalar GINIb 	 	 = `GiniBeta'
		return scalar bconverged  = (abs(`ffinal') <= `Xx')
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

		return scalar agq = `a'
		return scalar bgq = `b'
		return scalar cgq = `c'

		return scalar theta   =   `aatheta'
		return scalar gama    =   `aagama'
		return scalar delta   =   `aadelta'

		if ("`nochecks'" == "") {
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

		return scalar N			= `Nobs'
		return scalar mu        	= `mu'
		return scalar sd			= `sd'
		return scalar z`pl'         = `z'

	    return matrix results_`ppp'`mmm'  = `tmp`pl''
		 
	local mmm = `mmm' + 1

    * close multiple means		
	}

	return local  zlines  "`zl'"
	return scalar zl      = `Npline'
	return matrix results  = `rtmp'
		
	local ppp = `ppp' + 1

  * close multiple poverty lines		
  }

   return add

 restore

 
 }

end


********************************************************************************
* cleanversion ado
*! v1.0  4apr2020             by  JPA 		cleanversion
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


*-----------------------------------------------------------------------------
* v3.4 01Aug2026             by  JPA		groupdata
*   fix consistency check 2: it tested (a+c)>=1 while printing that value
*     next to the label L(1;pi)=1, so a curve with a+c=1.2945 was reported
*     as OK; it now evaluates the curve at p=1 and passes only if L(1)=1
*   fix the lognormal Gini: it was computed from ln(sd) where sd is already
*     the standard deviation of log welfare, i.e. a double log
*   return r(GINIln), the lognormal-approximation Gini, for comparison; it
*     is not derived from either fitted Lorenz curve
*   document the check encoding as it behaves (1 OK, 0 FAIL, missing when
*     not computed) instead of the -99 sentinel the code never returned
*   build the results-matrix rownames from the same 32-slot table the rows
*     are written into, instead of a fixed 28/32-name literal; the name count
*     can no longer disagree with the row count mkmat produces (r(503))
*   guard the grouped-data-only steps (keep if pg != .; the Lorenz table) on
*     grouped/type() as well as skip, so they no longer run for unitrecord
*   refuse standalone unitrecord: the parametric fit to raw unit records is
*     degenerate (GQ e>0 and missing throughout; Beta headcount 1.49 vs a
*     microdata 39.28). The checks do fire, but check1b/check2b are hardcoded
*     to 1 so two of four can never flag it, and nochecks reports nothing.
*     The guard is on grouped alone: unitrecord with type() aborts r(110) on
*     all four types, before this change too, from a tempvar collision;
*     refusing turns that into an actionable message. unitrecord with grouped
*     is unaffected
*-----------------------------------------------------------------------------
* v3.3 01Aug2026             by  JPA		groupdata
*   fix type() option validation: an empty type() was treated as a valid
*     match, which made the grouped option (and unit-record calls) error
*     out; validation now uses inlist()
*   fix "gen doulbe" typo that broke type(5) with fweights
*   fix inverted display of the Beta Lorenz condition 4 check
*   fix chained inequalities in the GQ Lorenz condition 4 check
*   fix undefined macro (coefbgq) and precedence in the coef*() validation
*   figures now use the first poverty line for their reference lines
*   honor user-supplied sd(); preserve and restore the caller's RNG state
*   fix duplicated row names (check3*/check4*) in the results matrix
*   return r(N); validate bins(); require an estimation mode; remove
*     unreachable code (gini_G/nsmean/npovline); fix typos in messages
*   fix type(6) without weights: the bin-midpoint delta used range
*     1/bins (overwriting the first bin, set from min(), with missing);
*     now 2/last, matching the pw/fw branches
*   return r(bconverged): convergence flag for the Beta headcount solver
*   deduplicate identical benchmark and return blocks; run the
*     dependency version checks once instead of once per command
*   fix stray double "in" range qualifiers (in 2/l in 2/`bins') that made
*     type(2), type(5) with fweights, and type(6) without weights abort
*     with r(198)
*   fix type(5) with fweights: the Lorenz numerator was unweighted while
*     its denominator was population-weighted; numerator is now exp2*inc
*   set weight2 to "fweight" when the caller supplies no weights, so the
*     per-type weight checks see the synthesised weight
*   guard the which_version dependency checks with capture, so a missing
*     which_version no longer aborts the command
*   fix multiple: the sample moments were measured inside the poverty-line
*     loop, whose body reduces the data to the grouped bins, so every line
*     after the first summarised the bins (mean 214.28 -> 92.06, FGT0 > 100)
*     and the run ended in r(503); they are now measured once, before it
*   fix r(GINIgq): it returned gini_ln, a lognormal expression, instead of
*     gini_tt, the GQ Lorenz Gini, which was computed and then discarded;
*     row 4 of r(results) had the same problem and was named gini_ln while
*     sitting in the GQ block. On the QA fixture the reported value was
*     -0.676, outside [0,1]; the GQ Gini is 0.1339, against a microdata
*     Gini of 0.1340. Row 4 is renamed GiniGQ to parallel GiniBeta.
* v3.2 01Mar2022             by  JPA		groupdata
*   add check for when the grouped data option is enabled
*   clarify help file, to ensure it is clear that grouped option should
*     only be used when unit records is provided
* v3.1 16Apr2021             by  JPA		groupdata
*   fix bug on the display of the lorenz table.
* 	debug is an undocumented option
* v3.0 13Apr2021             by  JPA		groupdata
*    add multiple option: multiple estimates are now stored as scalars
*    fix bugs on the reporting on elasticities
*    improve the help file 
* v 2.9 16jun2020             by  JPA
*   remove typo in line 643
* v 2.8  28apr2020             by  JPA
*   support welfare estimations based on provided coefficients
*   add multiple mean options
*   add debug milestones
*   return matrix includes mean, sd, and povline
* v 2.7  24apr2020             by  JPA
*   fix estiamtes using unit record data
*   estimate multiple lines
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