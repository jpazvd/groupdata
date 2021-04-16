{smcl}
{hline}
help for {cmd:groupdata}{right:Joao Pedro Azevedo}
{right:version 3.1}
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
{cmd:multiple}
]{p_end}


{p 4 4 2}{cmd:pweights}, {cmd:fweights} and {cmd:aweights} are allowed; see help weights. See help {help weight}.{p_end}


{title:Description}

{p 4 4 2}Poverty rates at an international poverty line were originally estimated by first fitting a parametric Lorenz curve to the grouped data and then using the functional relationship between the slope of the Lorenz curve and mean income to identify the headcount rate of poverty. The following relation when evaluated at the point representing the proportion of the poor in the population, the slope is equal to the ratio of the international poverty line to mean household expenditure (or income) per capita (see equation 1).{p_end}

{p 4 4 2}𝐿′ (𝑝) = 𝑧/𝜇 at 𝑝 = 𝐻 							(1){p_end}
 
{p 4 4 2}To calculate the slope of the Lorenz curve, the Lorenz curve is estimated using one of the following two functional forms – the Beta Lorenz curve and the General Quadratic (GQ) Lorenz curve. For example, if the Beta Lorenz Curve 𝐿(𝑝) = 𝑝 − 𝜃𝑝𝛾 (1 − 𝑝)𝛿 were used, three parameters 𝜃, 𝛾, and 𝛿 need to be estimated. There are four conditions which need to be satisfied by the estimated parameters for the Lorenz curve to be theoretically valid. There conditions are:{p_end}

{p 4 4 2}1. 𝐿(0) = 0{p_end}
{p 4 4 2}2. 𝐿(1) = 1{p_end}
{p 4 4 2}3. 𝐿′(0+) ≥ 0{p_end}
{p 4 4 2}4. 𝐿′′(𝑝) ≥ 0, 𝑝 ∈ (0,1){p_end}

{p 4 4 2}The first two conditions, which may be called boundary conditions, imply that 0 and 100 percent of the population account for 0 and 100 percent of the total income or expenditure, respectively. The third and
fourth conditions ensure that the Lorenz curve is monotonically increasing and convex. There is no guarantee that the estimated parameters of the Lorenz curve will satisfy all these conditions. If the Beta Lorenz curve is adopted, equation (1) becomes:{p_end}

{p 4 4 2}1 − 𝜃𝐻𝛾 (1 − 𝐻)𝛿 [(𝛾/𝐻) − (𝛿/(1−𝐻)] = (𝑧/𝜇) 		(2){p_end}
		
{p 4 4 2}Equation (2) clearly indicates that if we have the three parameters of the Lorenz curve, the poverty line and the mean household expenditure (or income), we can solve this equation to get the estimate of the poverty headcount rate (H). Poverty gaps, severity of poverty, and Gini coefficients can also be calculated from specific equations derived from the Lorenz curves (see also Datt 1998).{p_end} 

{title:Where}

{p 4 4 2}{opt z:l}{cmd:(}{it:# [# # #]}{cmd:)} is the poverty line which should be used. Support the specification of multiple poverty lines.{p_end}


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

{p 4 4 2}{opt unitrec:ord} runs the parametric lorenz using the unit records.{p_end}

{p 4 4 2}{opt nofig:ures} Omit the display of figures. By default, the Lorenz, PDF and Pen Parade will are  displayed.{p_end}

{p 4 4 2}{opt noe:lasticities} Omit the display of elasticities. By default, FGT(0), FGT(1) and FGT(2) elasticities with respect to the Mean and the Gini are reported.{p_end}

{p 4 4 2}{opt noc:hecks} Omit the display of consistency checks. By default, the internal consistency checks for both models are displayed. If the parametric lorez fails any of the checks, a warning will be displayed even if the nochecks option is selected.{p_end}

{p 4 4 2}{opt nol:orenz} Omit the table with the Lorenz curve. By default a table with the Lorenz curve is displayed.{p_end}

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

	{p 4 4 2}[Datt, Gaurav, 1998. "Computational Tools for Poverty Measurement and Analysis," FCND Discussion Paper 50, Washington, DC. Doi 10.22004/ag.econ.94862](10.22004/ag.econ.94862){p_end}

	{p 4 4 2}[World Bank. Povcalnet.] (http://iresearch.worldbank.org/PovcalNet/PovCalculator.aspx)	{p_end}
	
{title:ADO Dependencies}

    {p 4 4 2}Paul Corral & Minh Cong Nguyen & Joao Pedro Azevedo, 2018. "GROUPFUNCTION: Stata module to replace several basic collapse functions,"Statistical Software Components S458475, Boston College Department of Economics.{browse "https://ideas.repec.o/bocode/s458475.html":(link to publication)}{p_end}
 
    {p 4 4 2}Daniel Klein, 2019. "WHICH_VERSION: Stata module to return location and programmer's version of ado-files," Statistical Software Components S4584706, Boston College Department of Economics, revised 11 Nov 2019.{browse "https://ideas.repec.org/code/s458706.html":(link to publication)}{p_end}

	{p 4 4 2}[Joao Pedro Azevedo, 2006. "APOVERTY: Stata module to compute poverty measures," Statistical Software Components S456750, Boston College Department of Economics, revised 13 Apr 2007.](https://ideas.repec.org/c/boc/bocode/s456750.html){p_end}

	{p 4 4 2}[Joao Pedro Azevedo, 2006. "AINEQUAL: Stata module to compute measures of inequality," Statistical Software Components S456748, Boston College Department of Economics, revised 13 Apr 2007.](https://ideas.repec.org/c/boc/bocode/s456748.html){p_end}

	{p 4 4 2}[Joao Pedro Azevedo & Samuel Franco, 2006. "ALORENZ: Stata module to produce Pen's Parade, Lorenz and Generalised Lorenz curve," Statistical Software Components S456749, Boston College Department of Economics, revised 09 Jul 2012.](https://ideas.repec.org/c/boc/bocode/s456749.html){p_end}

{title:Keywords}

{p 4 4 2}Group Data; Parametrized Lorenz; Poverty Estimation; Pen's Parade; Lorenz; Generalized Lorenz{p_end}

{title:Authors}

	{p 4 4 2}Joao Pedro Azevedo, jazevedo@worldbank.org{p_end}
    {p 4 4 2}[jazevedo@worldbank.org](mailto:jazevedo@worldbank.org){p_end}  
    {p 4 4 2}World Bank{p_end}  
    {p 4 4 2}[personal page](http://www.worldbank.org/en/about/people/j/joao-pedro-azevedo){p_end}  
		
{title:Acknowledgements}
    {p 4 4 2}The authors would like to thank  {p_end}

{title:GitHub Respository}

{p 4 4 2}For previous releases please visit the GROUPDATA {browse "https://github.com/jpazvd/groupdata" :GitHub Repo}{p_end}


{title:Also see}

{p 2 4 2}Online:  help for {help apoverty}; {help ainequal};  {help wbopendata}; {help mpovline}; {help drdecomp}; {help skdecomp}; {help tabmult}; {help xtsur} (if installed){p_end} 


