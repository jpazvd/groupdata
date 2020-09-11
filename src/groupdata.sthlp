{smcl}
{hline}
help for {cmd:groupdata}{right:Joao Pedro Azevedo}
{right:version 2.9}
{hline}

{title:{cmd:groupdata} - Group Data Estimation of FGT0, FGT1, FGT2 and Gini}

{p 8 17}
{cmdab:groupdata}
{it:welfarevar}
[{cmd:weight}]
[{cmd:if} {it:exp}]
[{cmd:in} {it:exp}],
{opt z:l}{cmd:(}{it:# [# # #]}{cmd:)}
[ 
{opt type}{cmd:(}{it:numeric}{cmd:)}
{opt m:ean}{cmd:(}{it:# [# # #]}{cmd:)}
{opt bin:s}{cmd:(}{it:numeric}{cmd:)}
{opt coefb}{cmd:(}{it:gama delta theta}{cmd:)}
{opt coefgq}{cmd:(}{it:A B C}{cmd:)}
{opt sd}{cmd:(}{it:value}{cmd:)}
{opt min}{cmd:(}{it:value}{cmd:)}
{opt max}{cmd:(}{it:value}{cmd:)}
{opt group:ed}
{opt reg:ress}
{opt bench:mark}
{opt unitrec:ord}
{opt nofig:ures}
{opt noe:lasticities}
{opt noc:hecks}
{opt nol:orenz}
{cmd:debug}
]{p_end}


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

		  

*-----------------------------------------------------------------------------
*! v 2.9 16jun2020             by  JPA
* remove typo in line 643
* v 2.8  28apr2020             by  JPA
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



{p 4 4 2}{cmd:pweights}, {cmd:fweights} and {cmd:aweights} are allowed; see help weights. See help {help weight}.{p_end}


{title:Description}

{p 4 4 2}{p_end} 

{title:Where}



{p 4 4 2}{p_end} 

{title:Options}

{p 4 4 2}{cmd:{opt type(numeric)}}{p_end}  

{p 4 4 2}{cmd:{opt Type 1 grouped data}}: P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population{p_end}
{p 4 4 2}{cmd:{opt Type 2 grouped data}}: Q=Proportion of population, R=Proportion of incometype{p_end}
{p 4 4 2}{cmd:{opt Type 5 grouped data}}: W=Percentage of the population in a given interval of incomes, X=The mean income of that interval.{p_end}
{p 4 4 2}{cmd:{opt Type 6 grouped data}}: W=Percentage of the population in a given interval of incomes, X=The max income of that interval.{p_end}
{p 4 4 2}{cmd:{opt Unit record data}}: Percentage of the population with same income level, The income level.{p_end}

{p 4 4 2}{cmd:{opt in:dicator(string)}} poverty and inequality indicators. fgt0, fgt1, fgt2, gini, theil, and mean are the currently supported 
options.{p_end}


{p 4 4 2}{opt z:l}{cmd:(}{it:# [# # #]}{cmd:)}{p_end}
{p 4 4 2}{opt m:ean}{cmd:(}{it:# [# # #]}{cmd:)}{p_end}
{p 4 4 2}{opt bin:s}{cmd:(}{it:numeric}{cmd:)}{p_end}
{p 4 4 2}{opt coefb}{cmd:(}{it:gama delta theta}{cmd:)}{p_end}
{p 4 4 2}{opt coefgq}{cmd:(}{it:A B C}{cmd:)}{p_end}
{p 4 4 2}{opt sd}{cmd:(}{it:value}{cmd:)}{p_end}
{p 4 4 2}{opt min}{cmd:(}{it:value}{cmd:)}{p_end}
{p 4 4 2}{opt max}{cmd:(}{it:value}{cmd:)}{p_end}
{p 4 4 2}{opt group:ed}{p_end}
{p 4 4 2}{opt reg:ress}{p_end}
{p 4 4 2}{opt bench:mark}{p_end}
{p 4 4 2}{opt unitrec:ord}{p_end}
{p 4 4 2}{opt nofig:ures}{p_end}
{p 4 4 2}{opt noe:lasticities}{p_end}
{p 4 4 2}{opt noc:hecks}{p_end}
{p 4 4 2}{opt nol:orenz}{p_end}
{p 4 4 2}{cmd:debug}{p_end}

{title:Saved Results}

{cmd:groupdata} returns results in {hi:r()} format. 
By typing {helpb return list}, the following results are reported:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(path)}}number of paths of the shapley decomposition {p_end}
{synopt:{cmd:r(component)}}number of components of the decomposition {p_end}
{synopt:{cmd:r(N)}}number of observations utilized on the calculation{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}average effect of each components based on all paths.{p_end}
{synopt:{cmd:r(sd)}}standard deviation of the effects based on all paths. If option {hi:std} is specify. {p_end}
{synopt:{cmd:r(gic)}}average effect of each components based on all paths when the indicators are the changes on {it:welfarevar()} by bin.{p_end}
{synopt:{cmd:r(sd_gic)}}standard deviation of each components based on all paths when the indicators are the changes on {it:welfarevar()} by bin. If option {hi:std} is specify. {p_end}
{synopt:{cmd:r(stats)}}poverty and inequality indicators. If option {hi:stats} is specify. {p_end}
{synopt:{cmd:r(statsvar)}}summary statistics of factors. If option {hi:stats} is specify. {p_end}

{pstd}{cmd:Obs:} On the reported matrices {p_end}
{pstd}{it:Index label}: 0 - FGT(0); 1 - FGT(1); 2 - FGT(2); 3 - Gini; 4 - Theil; 5 - Mean; 6 - Bottom(); 7 - Top(); 8 - Bottom()/Mean; 9 - Middle(# #).{p_end}
{pstd}{it:Effect label}: 1 represents the first {it:component} listed on the command, and so on. Total of components plus 1 represents the total change on the indicator and plus 2 denotes the residual, when this option is specified.{p_end}

{pstd}{cmd:Important}: To guarantee precision, we recommend to use {it:double} when create variables.{p_end}


{title:Examples}

{p 8 12}{inp:. adecomp percapitainc laborinc nonlaborinc, by(year) equation(c1+c2) indicator(fgt0 fgt1 fgt2 gini theil) varpl(pline)}{p_end}


{title:References}

{p 4 4 2}{browse "https://ideas.repec.org/p/pra/mprapa/85584.html":(link to publication)}{p_end}
	
	
{title:ADO Dependencies}

    {p 4 4 2}Paul Corral & Minh Cong Nguyen & Joao Pedro Azevedo, 2018. "GROUPFUNCTION: Stata module to replace several basic collapse
    functions,"Statistical Software Components S458475, Boston College Department of Economics.{browse "https://ideas.repec.o
    /bocode/s458475.html":(link to publication)}{p_end}
 
    {p 4 4 2}Daniel Klein, 2019. "WHICH_VERSION: Stata module to return location and programmer's version of ado-files," Statistical
    Software Components S4584706, Boston College Department of Economics, revised 11 Nov 2019.{browse "https://ideas.repec.org/code/s458706.html":(link to publication)}{p_end}


{title:Authors}

	{p 4 4 2}Joao Pedro Azevedo, jazevedo@worldbank.org{p_end}
		
{title:Acknowledgements}
    {p 4 4 2}The authors would like to thank  {p_end}

{title:GitHub Respository}

{p 4 4 2}For previous releases please visit the GROUPDATA {browse "https://github.com/jpazvd/groupdata" :GitHub Repo}{p_end}


{title:Also see}

{p 2 4 2}Online:  help for {help apoverty}; {help ainequal};  {help wbopendata}; {help mpovline}; {help drdecomp}; {help skdecomp}; {help tabmult}; {help xtsur} (if installed){p_end} 