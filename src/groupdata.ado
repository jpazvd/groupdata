**********************************
*! v 2.2   06apr2020				  by JPA     		*
*   dependencies checks run quietly
*   apoverty and ainequal added to the dependencies check
* v 2.1   05apr2020				  by JPA     		*
*   changed ado name from grouppov to groupdata
* v 2.0   02apr2020				  by JPA     		*
*   changes made to use this method to estimate learning poverty 
* 	add support to aweight
*   replace wtile2 by alorenz
*   add microdata value as benchmark
* v 1.1   14jan2014				  by SM and SM		
*   change ado name from povcal to grouppov
*   technical note on Global Poverty Estimation: Theoratical and Empirical 
*   Validity of Parametric Lorenz Curve Estiamtes and Revisitng Non-parametric 
*   techniques. (January, 2014), for discussions on the World Bank Global 
*   Poverty Monitoring Working Group.
* v 1.0   02fev2012				  by SM and JPA 			*
*   povcal.ado created by Joao Pedro Azevedo and Shabana Mitra
**********************************

program define groupdata, rclass

    version 8.0

    syntax varlist(numeric min=1 max=1)         ///
                 [in] [if]                      ///
                 [fweight pweight aweight]      ///
                 ,                              ///
                         z(real)                ///
                    [							///
						 Mu(real -99)          	///
                         GROUPed                ///
                         BINs(real -99)         ///
                         REGress				///
						 BENCHmark				///
						 NOFIGure				///
					]

quietly {

	  *-----------------------------------------------------------------------------
	  * Download and install required user written ado's
	  *-----------------------------------------------------------------------------
	  * Fill this list will all user-written commands this project requires
		  local user_commands groupfunction alorenz which_version apoverty ainequal

	  * Loop over all the commands to test if they are already installed, if not, then install
		  qui foreach command of local user_commands {
			cap which `command'
			if _rc == 111 { 
				ssc install `command'
			}
			else {
				which_version groupfunction 
				if  (`s(version)' < 2.0) {
					ado update groupfunction , update
				}
				which_version alorenz
				if  (`s(version)' < 3.1) {
					ado update alorenz , update
				}
			}
		  }

						
		**********************************
		* Temp names 
		
		tempname A  gq cofb cof  gqg cofbg
	
		tempvar  temp touse rnd lninc  pp pw L p y1 y2 a b c  x1 x2  Lg pg yg ag bg cg yg2 x1g x2g  type model var value
	
	
		**********************************
		* Locals 
		
    if ("`weight'" == "") {
        tempvar wtg
        gen `wtg' = 1
        loc weight "fw"
        loc exp    "=`wtg'"
        local pop "`wtg'"
    }
    else {
        local pop =subinstr("`exp'","=","",.)
    }

    if ("`regress'" != "") {
        loc noi2 "noi "
    }
    else {
        loc noi2 ""
    }

    tokenize `varlist'
    local inc `1'

    mark `touse' `if' `in' [`weight'`exp']
	
    markout `touse' `varlist'

		**********************************
		* Microdata
		
		if ("`benchmark'" == "benchmark") {
			apoverty `inc' [`weight'`exp'] 	if `touse', line(`z')  fgt3  pgr
			local afgt0 = r(head_1) 
			local afgt1 = r(pogapr_1) 
			local afgt2 = r(fogto3_1) 
			ainequal `inc' [`weight'`exp']  if `touse'
			local agini = r(gini_1) 
		}

        **********************************

        gen double `rnd' = uniform()		if `touse'
        gen `lninc' = ln(`inc') 			if `touse'

        sort `inc' `rnd'

        if (`mu' == -99) {
            sum `inc' [`weight'`exp'] 		if `touse'
            local mu = `r(mean)'

            sum `lnmpce' [`weight'`exp']	if `touse'
            local lnmu = r(mean)
            local lnsd = r(sd)
        }
        else {
            sum `lnmpce' [`weight'`exp']	if `touse'
            local lnmu = ln(`mu')
            local lnsd = r(sd)
        }

        qui if ("`grouped'" == "") {
			
			noi di ""
			noi di ""
			noi di "Estimation using using available data, either microdata or grouped data estimated elsewhere."

            ************************************
            ** cumulative distribution
            ************************************

            egen double `pw' = pc(`inc')			if `touse', prop
            egen double `pp' = pc(`pop')			if `touse', prop

            gen double `L' = `pw'					if `touse'
            replace `L' = `pw'+`L'[_n-1] in 2/l		if `touse'

            gen double `p' = `pp'					if `touse'
            replace `p' = `pp'+`p'[_n-1] in 2/l		if `touse'

            ************************************
            ** generate variables (GQ Lorenz Curve)
            ************************************

            gen double `y1' = `L'*(1-`L')			if `touse'
            gen double `a' = ((`p'^2)-`L')			if `touse'
            gen double `b' = `L'*(`p'-1)			if `touse'
            gen double `c' = (`p'-`L')				if `touse'

            ************************************
            ** generate variables Beta Lorenz Curve
            ************************************

            gen double `y2'=ln(`p'-`L')				if `touse'
            gen double `x1'=ln(`p')					if `touse'
            gen double `x2'=ln(1-`p')				if `touse'

            local last = _N-1

            ************************************
			** Plot Figure 
            ************************************

			if ("`nofigure'" == "") {
			    
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

			gen y1 = `y1' 							if `touse'
			gen  a = `a' 							if `touse'
			gen  b = `b' 							if `touse'
			gen  c = `c'							if `touse'

            `noi2' di ""
            `noi2' di ""
            `noi2' di as text "Estimation: " as res "GQ Lorenz Curve"
            `noi2' reg y1 a b c 	in 1/`last'		if `touse', noconstant
*            `noi2' reg `y1' `a' `b' `c' in 1/`last', noconstant
            est store gq
            mat `gq' = e(b)
            mat `cof' = e(b)

            ************************************
            ** Estimation: Beta Lorenz Curve
            ************************************

			gen y2 = `y2' 							if `touse'
			gen x1 = `x1' 							if `touse'
			gen x2 = `x2'							if `touse'
			
            `noi2' di ""
            `noi2' di ""
            `noi2' di as text "Estimation: " as res "Beta Lorenz Curve"
            `noi2' reg y2 x1 x2 	in 1/`last'		if `touse'
 *           `noi2' reg `y2' `x1' `x2' in 1/`last'
            est store beta
            mat `cofb' = e(b)

        }

********************************************************************************
********************************************************************************
********************************************************************************
		
        qui if ("`grouped'" != "") {

			noi di ""
			noi di "Estimation using grouped data..."

            ** cumulative distribution (grouped data)
			
			if (`bins'!= 0) {
				if (`bins' == -99) {
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
			
			mat `A' = r(lorenz1)
			
			svmat double `A'
			
			return matrix data = `A'

            ** generate variables (GQ Lorenz Curve) (grouped data)

            gen double `Lg' = `A'2/100
            gen double `pg' = `A'4/100

            gen double `yg' = `Lg'*(1-`Lg')
            gen double `ag' = ((`pg'^2)-`Lg')
            gen double `bg' = `Lg'*(`pg'-1)
            gen double `cg' = (`pg'-`Lg')

            ** generate variables Beta Lorenz Curve (Grouped data)

            gen double `yg2'=ln(`pg'-`Lg')
            gen double `x1g'=ln(`pg')
            gen double `x2g'=ln(1-`pg')

            local lastg = `bins'-1

            ************************************
			** Plot Figure 
            ************************************

			if ("`nofigure'" == "") {
				local mustr = strofreal(`mu',"%9.2f")
				local intercept00 = `bins'+1
				replace `Lg' = 0 in `intercept00'
				replace `pg' = 0 in `intercept00'
				
				graph twoway lowess `Lg' `pg', 										///
					ytitle("Lorenz") xtitle("Population (Cumulative)") 				///
					note("mean: `mustr' [`bins' bins]") name(lorenz, replace)
								
				kdensity `A'6, 														///
					xline(`z') xtitle("`inc'") name(pdf, replace)

				graph twoway lowess `A'3 `pg', 										///
					yline(`z') ytitle("`inc'") xtitle("Population (Cumulative)") 	///
					note("mean: `mustr' [`bins' bins]") name("pen", replace)
	
			}

            ************************************
            ** Estimation: GQ Lorenz Curve (grouped data)
            ************************************
			
			gen yg = `yg' 
			gen ag = `ag' 
			gen bg = `bg' 
			gen cg = `cg' 
						
            `noi2' di ""
            `noi2' di ""
            `noi2' di as text "Estimation: " as res "GQ Lorenz Curve (grouped data)"
            `noi2' reg yg ag bg cg in 1/`lastg', noconstant
*            `noi2' reg `yg' `ag' `bg' `cg' in 1/`lastg', noconstant
            est store gqg
            mat `gqg' = e(b)

            ************************************
            ** Estimation: Beta Lorenz Curve (Grouped data)
            ************************************

			gen yg2 = `yg2' 
			gen x1g = `x1g' 
			gen x2g = `x2g'
			
            `noi2' di ""
            `noi2' di ""
            `noi2' di as text "Estimation: " as res "Beta Lorenz Curve (Grouped data)"
            `noi2' reg yg2 x1g x2g  in 1/`lastg'
*            `noi2' reg `yg2' `x1g' `x2g'  in 1/`lastg'
            est store blcg
            mat `cofbg' = e(b)

        }

        /**************************************
        ** Test
        **************************************

        save tmp0 , replace

        preserve
        use y a b c using tmp0 , clear
        save tmp1, replace
        use yg ag bg cg using tmp0 , clear
        rename yg y
        rename ag a
        rename bg b
        rename cg c
        gen group = 2
        drop if y == .
        save tmp2, replace
        use tmp1, clear
        gen group = 1
        append using tmp2
        tab group

        ** GQ Lorenz Curve

        regress y a b c  if group == 1, noconstant
        est store gq

        ** GQ Lorenz Curve (grouped data)

        regress y a b c   if group == 2, noconstant
        est store gqg

        suest gq gqg
        test [gq_mean = gqg_mean]

        restore

        **************************************/
        /* Table 2 (Datt, 1998)             */
        **************************************
        /** GQ Lorenz Curve */
        **************************************


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

        **************************************
        /** Beta Lorenz Curve               */
        **************************************

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

        			while `hcrb2'-`hcrb1'>.0001 & `i'<500{
        				local ff2=`aatheta'*`hcrb2'^`aagama'*(1-`hcrb2')^`aadelta'*(`aagama'*(`aagama'-1)/*
        				*//`hcrb2'^2-2*`aagama'*`aadelta'/(`hcrb2'*(1-`hcrb2'))+`aadelta'*(`aadelta'-1)/(1-`hcrb2')^2)
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
        		if abs(`ff')> `Xx'{
        			local hcrb4=.0001
        			local hcrb3 = .0001
        			local j=1
        			local fff=`aatheta'*`hcrb3'^`aagama'*(1-`hcrb3')^`aadelta'*((`aagama'/`hcrb3')-(`aadelta'/(1-`hcrb3')))-1+`z'/`mu'
        			while abs(`fff')>`Xx' & `j'<10000{
        				local hcrb3 = `hcrb3'+.0001
        				local j = `j'+ 1
        				local fff1=`aatheta'*`hcrb3'^`aagama'*(1-`hcrb3')^`aadelta'*((`aagama'/`hcrb3')-(`aadelta'/(1-`hcrb3')))-1+`z'/`mu'
        				if abs(`fff1')>abs(`fff'){
        					local fff = `fff'
        				}
        			else{
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
        	local GiniBeta = 2*`aatheta'*exp(lngamma(1+`aagama'))*exp(lngamma(1+`aadelta'))/exp(lngamma/*
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


        *********************************************************
        **  Checking for consistency of lorenz curve estimation (section 4)
        *********************************************************

        ***********************
        /* GQ Lorenz Curve */
        ***********************
        quietly {

            noi di ""
            noi di ""
            noi di as text "Checking for consistency of lorenz curve estimation: " as res "GQ Lorenz Curve"

            /** Condition 1 */
            if (`e' < 0) {
                noi di as text "L(0;pi)=0: " as res  "OK"
                local ccheck1 = 1
            }
            else {
                noi di as text "L(0;pi)=0: " as err "FAIL"
                local ccheck1 = 0
            }

            /** Condition 2 */
            local t = (`a'+`c')
            if (`t' >= 1) {
                noi di as text "L(1;pi)=1: " as res "OK (value=" %9.4f `t' ")"
                local ccheck2 = 1
            }
            else {
                noi di as text "L(1;pi)=1: " as err "FAIL (value=" %9.4f `t' ")"
                local ccheck2 = 0
            }

            /** Condition 3 */
            if (`c' >= 0) {
                noi di as text "L'(0+;pi)>=0: " as res  "OK"
                local ccheck3 = 1
            }
            else {
                noi di as text "L'(0+;pi)>=0: " as err "FAIL"
                local ccheck3 = 0
            }


            /** Condition 4 */

            if ( `m' < 0 | (( 0 < `m' <(`n'^2/(4*`e'^2)))	& `n' >= 0) | ((0 < `m' < (-`n'/2)) & (`m' < (`n'^2 /(4*`e'^2))))) {
                noi di as text "L''(p;pi)>=0 for p within (0,1): " as res  "OK"
                local ccheck4 = 1
            }
            else {
                noi di as text "L''(p;pi)>=0 for p within (0,1): " as err "FAIL"
                local ccheck4 = 0
            }

        }

        ***********************
        /* Beta Lorenz curve */
        ***********************

            noi di ""
            noi di as text "Checking for consistency of lorenz curve estimation: " as res "Beta Lorenz curve"

        /** Condition 1 */
        * automatically satisfied by the functional form

        /** Condition 2 */
        * automatically satisfied by the functional form

        /** Condition 3 */
        	* We check the validity of the Beta Lorenz curve
        	local check1 = 1- `aatheta'*.001^`aagama'*.999^`aadelta'*(`aagama'/.001-`aadelta'/.999)

        /** Condition 4 */

        	local check2 = 0
        	local i=.01
        	while `i'<1{
        		local chk = `aatheta'*`i'^`aagama'*(1-`i')^`aadelta'*((`aagama'*(1-`aagama')/`i'^2)+(2*`aagama'*`aadelta'/*
        		*//(`i'*(1-`i')))+(`aadelta'*(1-`aadelta')/(1-`i')^2))
        		if `chk'<0{
        			local check2=1
        		}
        		else{
        		}
        		local i=`i'+.01
        	}

        noi di as text "L(0;pi)=0: " as res "OK (automatically satisfied by the functional form)"

        noi di as text "L(1;pi)=1: " as res "OK (automatically satisfied by the functional form)"

        if `check1'>=0  {
            noi di as text "L'(0+;pi)>=0: " as res  "OK"
			local bcheck3 = 1
        }
        else {
            noi di as text "L'(0+;pi)>=0: " as err "FAIL "
			local bcheck3 = 0
        }

        if `check2'==0 {
            noi di as text "L''(p;pi)>=0 for p within (0,1): " as res  "OK"
			local bcheck4 = 1
        }
        else {
            noi di as text "L''(p;pi)>=0 for p within (0,1): " as err "FAIL"
			local bcheck4 = 0
        }

        /**************************************************
        /* Choice of the Lorenz curve                   */
        **************************************************

        ******test stat for GQ Lorenz******

        estimates restore gqg
        predict lhatg if _est_gqg==1
        gen Lhatg=lhatg
        drop lhatg
        if _est_gqg==1 {
            local k_t=(pg<`H')
        }
        else {
        local k_t=.
        }
        if `k_t'==1{
        local testGQ=(`Lhatg'-yg)^2
        }
        else {
        local testGQ=.
        }
        sum `testGQ'
        local GQ_TT=r(sum)

        *******test stat for Beta Lorenz**************
        estimates restore gqg
        predict lhatgBeta if  _est_blcg==1
        local LhatgBeta=lhatg
        drop lhatgBeta
         if  _est_blcg==1 {
        local k_tBeta=(pg<`hcrb')
        }
        else {
        local k_tBeta=.
        }
        if `k_tBeta'==1 {
        local testBeta=(`LhatgBeta'-yg)^2
        }
        else {
        local testBeta=.
        }

        sum `testBeta'
        local Beta_TT=r(sum)

        local test=(`GQ_TT'<`Beta_TT')

        if `test==1{
            noi di as res "GQ has a lower statistic"
        }
        else {
            noi di as res "Beta has a lower statistic"
        }

        ****************************************/
        ** Output
        ****************************************

        /*** Display results */

        gen `type'  = .
        gen `model' = .
        gen `var'   = .
        gen `value' = .

        replace `var'   = _n in 1/24

        * main results type = 1
		replace `type'  = 1     in 1/8
        
		*elasticities lines (type=2 and type=3)
		replace `type'  = 2     	in  9
        replace `type'  = 3     	in  10
        replace `type'  = 2     	in  11
        replace `type'  = 3     	in  12
        replace `type'  = 2     	in  13
        replace `type'  = 3     	in  14
        replace `type'  = 2     	in  15
        replace `type'  = 3     	in  16
        replace `type'  = 2     	in  17
        replace `type'  = 3     	in  18
        replace `type'  = 2     	in  19
        replace `type'  = 3     	in  20

		* model types 	
        replace `model' = 	1   	in 1/4
        replace `model' = 	1     	in 9/14
        replace `model' = 	2     	in 5/8
        replace `model' = 	2     	in 15/20
		
		
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
			replace `type'	=	1 		in 21
			replace `type'	=	1 		in 22
			replace `type'	=	1 		in 23
			replace `type'	=	1 		in 24
			* add apoverty and ainequal model (model=0)
			replace `model'	=	0		in 21/24
			* add apoverty and ainequal values
			replace `value' = `afgt0'            in  21
			replace `value' = `afgt1'            in  22
			replace `value' = `afgt2'            in  23
			replace `value' = `agini'            in  24
			* add output label
			replace `var' = 1       in  21
			replace `var' = 2       in  22
			replace `var' = 3       in  23
			replace `var' = 4       in  24
		}
		
        label define var 1 "FGT(0)", add modify
        label define var 2 "FGT(1)", add modify
        label define var 3 "FGT(2)", add modify
        label define var 4 "Gini", add modify

        label define model 0 "Microdata", add modify
        label define model 1 "QG Lorenz Curve", add modify
        label define model 2 "Beta Lorenz Curve", add modify

        label define type 1 "Estimated Value", add modify
        label define type 2 "with respect to the Mean", add modify
        label define type 3 "with respect to the Gini", add modify

*         gen type = `type'
*         gen model = `model'
*         gen var     = `var'
*         gen value   = `value'

        label values `model' model
        label values `type' type
        label values `var' var
		
		label var `model' Model
		label var `type'  Type
		label var `var'   Indicator

        noi di ""
        noi di ""
        noi di "Estimated Poverty and Inequality Measures:"
        noi tabdisp `var' `model' if `var' != . & `type' == 1, cell(`value')
        noi di "Mean Income/Expenditure: " as res %16.2f `mu'

        noi di ""
        noi di ""
        noi di "Estimated Elasticities:"
        noi tabdisp `var' `model' `type' if `var' != . & `type' != 1 & `value' != . , cell(`value')

        /*** Store results */

        return scalar Hgq   = `H'*100
        return scalar PGgq  = `PG'*100
        return scalar SPGgq = `SPG'*100
        return scalar GINIgq  = `gini_ln'
        return scalar Hb    = `hcrb'*100
        return scalar PGb   = `PgBeta'*100
        return scalar SPGb  = `FgtBeta'*100
        return scalar GINIb = `GiniBeta'
        return scalar  elhmu       =    `elhmu'
        return scalar  elhgini     =    `elhgini'
        return scalar  elpgmu      =    `elpgmu'
        return scalar  elpggini    =    `elpggini'
        return scalar  elspgmu     =    `elspgmu'
        return scalar  elspggini   =    `elspggini'
        return scalar  elhmub      =    `elhmub'
        return scalar  elhginib    =    `elhginib'
        return scalar  elpgmub     =    `elpgmub'
        return scalar  elpgginib   =    `elpgginib'
        return scalar  elspgmub    =    `elspgmub'
        return scalar  elspgginib  =    `elspgginib'
        return scalar check1b   = 1
        return scalar check2b   = 1
        return scalar check3b   = `bcheck3'
        return scalar check4b   = `bcheck4'
        return scalar check1gq  = `ccheck1'
        return scalar check2gq  = `ccheck2'
        return scalar check3gq  = `ccheck3'
        return scalar check4gq  = `ccheck4'
        return scalar mu        = `mu'
        return scalar t         = `t'
		
}

	return add

	cap: drop yg ag bg cg yg2 x1g x2g
	cap: drop y1 a b c y2 x1 x2

end
