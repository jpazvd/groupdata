{smcl}
{hline}
help for {cmd:groupdata}{right:Joao Pedro Azevedo}
{right:version 3.0}
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
{cmd:multiple}
]{p_end}


{p 4 4 2}{cmd:pweights}, {cmd:fweights} and {cmd:aweights} are allowed; see help weights. See help {help weight}.{p_end}


{title:Description}

{p 4 4 2}{p_end} 

{title:Where}

{p 4 4 2}{opt z:l}{cmd:(}{it:# [# # #]}{cmd:)} Poverty lines{p_end}


{title:Options}

{p 4 4 2}{opt m:ean}{cmd:(}{it:# [# # #]}{cmd:)} Mean value of variable interest (i.e. income; consumption; learning){p_end}

{p 4 4 2}{opt bin:s}{cmd:(}{it:numeric}{cmd:)} Number of bins to be constructed. This option is only allowed when using microdata.{p_end}

{p 4 4 2}{opt coefb}{cmd:(}{it:gama delta theta}{cmd:)} Vector of coefficients estimates using the Beta Lorenz model. The oder of this coefficients important; please make sure the order is preserved.{p_end}

{p 4 4 2}{opt coefgq}{cmd:(}{it:A B C}{cmd:)} Vector of coefficients estimates using the QG  Lorenz model. The oder of this coefficients important; please make sure the order is preserved.{p_end}

{p 4 4 2}{opt sd}{cmd:(}{it:value}{cmd:)} Standard deviation from the sample.{p_end}

{p 4 4 2}{opt min}{cmd:(}{it:value} Minimum value of the distribution.{cmd:)}{p_end}

{p 4 4 2}{opt max}{cmd:(}{it:value}{cmd:)} Maximum value of the distribution.{p_end}

{p 4 4 2}{opt group:ed} Estimates using groupped  data.{p_end}

{p 4 4 2}{opt reg:ress} Distplay regression table.{p_end}

{p 4 4 2}{opt bench:mark} Benchmark parametric lorenz estimates against the estimates using microdata. This option is only allowed when using microdata.{p_end}

{p 4 4 2}{opt unitrec:ord} Confirm the availability of unti records.{p_end}

{p 4 4 2}{opt nofig:ures} Omit the display of figures.{p_end}

{p 4 4 2}{opt noe:lasticities} Omit the display of elasticities.{p_end}

{p 4 4 2}{opt noc:hecks} Omit the display of {p_end}

{p 4 4 2}{opt nol:orenz} Omit the table with the Lorenz curve.{p_end}

{p 4 4 2}{cmd:debug} Run code in debug mode.{p_end}

{p 4 4 2}{cmd:binvar}{cmd:(}{it:varname}{cmd:)} Specify bin variable{p_end}

{p 4 4 2}{cmd:{opt type(numeric)}} Specify the type of group data used.{p_end}  

{p 4 4 2}{cmd:{opt Type 1 grouped data}}: P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population{p_end}
{p 4 4 2}{cmd:{opt Type 2 grouped data}}: Q=Proportion of population, R=Proportion of incometype{p_end}
{p 4 4 2}{cmd:{opt Type 5 grouped data}}: W=Percentage of the population in a given interval of incomes, X=The mean income of that interval.{p_end}
{p 4 4 2}{cmd:{opt Type 6 grouped data}}: W=Percentage of the population in a given interval of incomes, X=The max income of that interval.{p_end}
{p 4 4 2}{cmd:{opt Unit record data}}: Percentage of the population with same income level, The income level.{p_end}

{p 4 4 2}{cmd:multiple} Returns scalars from each mu and z used.{p_end}


{title:Saved Results}

{cmd:groupdata} returns results in {hi:r()} format. 
By typing {helpb return list}, the following results are reported:

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}  	{p_end}
{synopt:{cmd:r(zl)}}	{p_end}
{synopt:{cmd:r(zpl0)}} {p_end}
{synopt:{cmd:r(sd)}}	{p_end}
{synopt:{cmd:r(mu)}} 	{p_end}

{p2col 7 20 24 2: Results QG Lorenz Curve}{p_end}
{synopt:{cmd:r(Hgq)}}FGT0{p_end}
{synopt:{cmd:r(PGgq)}}FGT1{p_end}
{synopt:{cmd:r(SPGgq)}}FGT2{p_end}
{synopt:{cmd:r(GINIgq)}}Gini{p_end}

{p2col 7 20 24 2: Results Beta Lorenz Curve}{p_end}
{synopt:{cmd:r(Hb)}}FGT0{p_end}
{synopt:{cmd:r(PGb)}}FGT1{p_end}
{synopt:{cmd:r(SPGb)}}FGT2{p_end}
{synopt:{cmd:r(GINIb)}}Gini{p_end}

{p2col 7 20 24 2: Checks QG Lorenz Curve}{p_end}
{synopt:{cmd:r(check1gq)}}L(0;pi)=0:{p_end}
{synopt:{cmd:r(check2gq)}}L(1;pi)=1:{p_end}
{synopt:{cmd:r(check3gq)}}L'(0+;pi)>=0{p_end}
{synopt:{cmd:r(check4gq)}}L''(p;pi)>=0 for p within (0,1){p_end}
{synopt:{cmd:r(t)}} value of the Lorenz intercept at L(1;pi)=1{p_end}

{p2col 7 20 24 2: Checks Beta Lorenz Curve}{p_end}
{synopt:{cmd:r(check1b)}}L(0;pi)=0 (automatically satisfied by the functional form){p_end}
{synopt:{cmd:r(check2b)}}L(1;pi)=1 (automatically satisfied by the functional form){p_end}
{synopt:{cmd:r(check3b)}}L'(0+;pi)>=0{p_end}
{synopt:{cmd:r(check4b)}}L''(p;pi)>=0 for p within (0,1){p_end}
 
{p2col 7 20 24 2: Estimated Elasticities}{p_end}
{synopt:{cmd:r(elpgmub)}}with respect to the Mean{p_end}
{synopt:{cmd:r(elpgginib)}}with respect to the Gini{p_end}
{synopt:{cmd:r(elspgmub)}}with respect to the Mean{p_end}
{synopt:{cmd:r(elspgginib)}}with respect to the Gini{p_end}

{synopt:{cmd:r(elspgmu)}}with respect to the Mean{p_end}
{synopt:{cmd:r(elspggini)}}with respect to the Gini {p_end}
{synopt:{cmd:r(elhmub)}}with respect to the Mean{p_end}
{synopt:{cmd:r(elhginib)}}with respect to the Gini {p_end}

{synopt:{cmd:r(elhmu)}}with respect to the Mean{p_end}
{synopt:{cmd:r(elhgini)}}with respect to the Gini {p_end}
{synopt:{cmd:r(elpgmu)}}with respect to the Mean{p_end}
{synopt:{cmd:r(elpggini)}}with respect to the Gini{p_end}

{p2col 7 20 24 2: Coefficients QG Lorenz Curve}{p_end}
{synopt:{cmd:r(agq)}}{p_end}
{synopt:{cmd:r(bgq)}}{p_end}
{synopt:{cmd:r(cgq)}}{p_end}

{p2col 7 20 24 2: Coefficients Beta Lorenz Curve}{p_end}
{synopt:{cmd:r(theta)}}{p_end}
{synopt:{cmd:r(gama)}}{p_end}
{synopt:{cmd:r(delta)}}{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(zlines)}} Last poverty line used.{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}ouptut matrix with nine collumns.{p_end}

{p2col 5 20 24 2:}{cmd:povline}: value of the poverty line used.{p_end} 
{p2col 5 20 24 2:}{cmd:seqpov}: sequence of the poverty line estimate.{p_end} 
{p2col 5 20 24 2:}{cmd:seqmean}: sequence of the mean used.{p_end} 
{p2col 5 20 24 2:}{cmd:mean}: value of the mean used.{p_end} 
{p2col 5 20 24 2:}{cmd:sd}: value of the mean used.{p_end} 
{p2col 5 20 24 2:}{cmd:indicator}{p_end}
{synopt:}1 FGT 0{p_end}
{synopt:}2 FGT 1{p_end}
{synopt:}3 FGT 2{p_end}
{synopt:}4 Gini{p_end}
{synopt:}5 L(0;pi)=0{p_end}
{synopt:}6 L(1;pi)=1{p_end}
{synopt:}7 L'(0+;pi)>=0{p_end}
{synopt:}9 L''(p;pi)>=0 for p within (0,1){p_end}
{p2col 5 20 24 2:}{cmd:model}{p_end}
{synopt:}0 Unit Records{p_end}
{synopt:}1 QQ Lorenz{p_end}
{synopt:}2 Beta Lorenz Curve{p_end}
{p2col 5 20 24 2:}{cmd:type}{p_end}
{synopt:}1 Estimated Value{p_end}
{synopt:}2 with respect to the Mean{p_end}
{synopt:}3 with respect to the Gini{p_end}
{synopt:}4 Checking for consistency of lorenz curve estimation{p_end}
{p2col 5 20 24 2:}{cmd:value}{p_end}
{synopt:}1 NA{p_end}
{synopt:}2 OK{p_end}
{synopt:}3 FAIL{p_end}

{synopt:{cmd:r(data)}}data table with the distributional data used to estimate the model the parametric lorenz{p_end} 
{p2col 5 20 24 2:}{cmd:percentile}{p_end} 
{p2col 5 20 24 2:}{cmd:cumulative distribution of the variable of interest}{p_end}
{p2col 5 20 24 2:}{cmd:max value}{p_end} 
{p2col 5 20 24 2:}{cmd:cumulative distribution of the weights}{p_end} 
{p2col 5 20 24 2:}{cmd:cumulative mean of the variable of interest}{p_end} 
{p2col 5 20 24 2:}{cmd:mean value of variable of interest}{p_end}

{pstd}{cmd:Important}: To guarantee precision, we recommend to use {it:double} when exporting variables from matrix to the dataset.{p_end}


{title:Examples}

{p 8 12}{inp:. groupdata PV1_R  [aw=WT2019] if cnt == "VNM", z(317) bins(20) m(336.45) group  nofigure  nol }{p_end}

{p 8 12}{inp:. groupdata PV1_R  [aw=WT2019] if cnt == "VNM", z(317) bins(20) m(336.45) group  nofigure  nol noe noc }{p_end}

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

