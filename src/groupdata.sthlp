{smcl}
{hline}
help for {cmd:groupdata}{right:Joao Pedro Azevedo}
{right:version 3.3}
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
{opt binvar}{cmd:(}{it:varname}{cmd:)}
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


{p 4 4 2}{cmd:pweights}, {cmd:fweights} and {cmd:aweights} are allowed; see help {help weight}. The weights accepted depend on the type of data provided: Types 1 and 2 accept only {cmd:aweights}; Types 5 and 6 accept {cmd:pweights}, {cmd:fweights}, or no weights.{p_end}


{title:Description}

{p 4 4 2}Poverty rates at an international poverty line were originally estimated by first fitting a parametric Lorenz curve to the grouped data and then using the functional relationship between the slope of the Lorenz curve and mean income to identify the headcount rate of poverty. Evaluated at the point representing the proportion of the poor in the population, the slope of the Lorenz curve is equal to the ratio of the poverty line to mean household expenditure (or income) per capita (see equation 1).{p_end}

{p 4 4 2}L'(p) = z/mu at p = H 							(1){p_end}

{p 4 4 2}To calculate the slope of the Lorenz curve, the Lorenz curve is estimated using one of the following two functional forms - the Beta Lorenz curve and the General Quadratic (GQ) Lorenz curve. For example, if the Beta Lorenz curve L(p) = p - theta*p^gama*(1-p)^delta were used, three parameters (theta, gama, and delta) need to be estimated. There are four conditions which need to be satisfied by the estimated parameters for the Lorenz curve to be theoretically valid. These conditions are:{p_end}

{p 4 4 2}1. L(0) = 0{p_end}
{p 4 4 2}2. L(1) = 1{p_end}
{p 4 4 2}3. L'(0+) >= 0{p_end}
{p 4 4 2}4. L''(p) >= 0, p in (0,1){p_end}

{p 4 4 2}The first two conditions, which may be called boundary conditions, imply that 0 and 100 percent of the population account for 0 and 100 percent of the total income or expenditure, respectively. The third and fourth conditions ensure that the Lorenz curve is monotonically increasing and convex. There is no guarantee that the estimated parameters of the Lorenz curve will satisfy all these conditions, so {cmd:groupdata} checks and reports each of them. If the Beta Lorenz curve is adopted, equation (1) becomes:{p_end}

{p 4 4 2}1 - theta*H^gama*(1-H)^delta*[(gama/H) - (delta/(1-H))] = z/mu 		(2){p_end}

{p 4 4 2}Equation (2) indicates that if we have the three parameters of the Lorenz curve, the poverty line and the mean household expenditure (or income), we can solve this equation to get the estimate of the poverty headcount rate (H). Poverty gaps, severity of poverty, and Gini coefficients can also be calculated from specific equations derived from the Lorenz curves (see also Datt 1998).{p_end}

{title:Where}

{p 4 4 2}{opt z:l}{cmd:(}{it:# [# # #]}{cmd:)} is the poverty line to be used. Multiple poverty lines may be specified.{p_end}


{title:Options}

{p 4 4 2}{opt type}{cmd:(}{it:numeric}{cmd:)} Specify the type of grouped data provided (1, 2, 5, or 6). Requires {opt mean()} and {opt binvar()}. It cannot be combined with the {opt grouped} option.{p_end}

{p 8 8 2}{cmd:Type 1}: P=Cumulative proportion of population, L=Cumulative proportion of income held by that proportion of the population. Only {cmd:aweights} are accepted.{p_end}
{p 8 8 2}{cmd:Type 2}: Q=Proportion of population, R=Proportion of income. Only {cmd:aweights} are accepted.{p_end}
{p 8 8 2}{cmd:Type 5}: W=Percentage of the population in a given interval of incomes, X=The mean income of that interval. {cmd:pweights}, {cmd:fweights}, or no weights are accepted.{p_end}
{p 8 8 2}{cmd:Type 6}: W=Percentage of the population in a given interval of incomes, X=The maximum income of that interval. Requires {opt min()} and {opt max()}. {cmd:pweights}, {cmd:fweights}, or no weights are accepted.{p_end}

{p 4 4 2}{opt binvar}{cmd:(}{it:varname}{cmd:)} Variable identifying the bins of the grouped data. Required with {opt type()}.{p_end}

{p 4 4 2}{opt m:ean}{cmd:(}{it:# [# # #]}{cmd:)} Mean value of the variable of interest (i.e. income; consumption; learning). Required with {opt type()}; multiple mean values may be specified.{p_end}

{p 4 4 2}{opt bin:s}{cmd:(}{it:numeric}{cmd:)} Number of bins to be constructed (minimum 4; default 20). This option is only allowed when using microdata with the {opt grouped} option.{p_end}

{p 4 4 2}{opt coefb}{cmd:(}{it:gama delta theta}{cmd:)} Vector of coefficient estimates from the Beta Lorenz model. The order of the coefficients is important; please make sure the order is preserved. Both {opt coefb()} and {opt coefgq()} must be specified together.{p_end}

{p 4 4 2}{opt coefgq}{cmd:(}{it:A B C}{cmd:)} Vector of coefficient estimates from the GQ Lorenz model. The order of the coefficients is important; please make sure the order is preserved. Both {opt coefb()} and {opt coefgq()} must be specified together.{p_end}

{p 4 4 2}{opt sd}{cmd:(}{it:value}{cmd:)} Standard deviation of the sample. If not specified, it is estimated from the data.{p_end}

{p 4 4 2}{opt min}{cmd:(}{it:value}{cmd:)} Minimum value of the distribution. Required with {opt type(6)}.{p_end}

{p 4 4 2}{opt max}{cmd:(}{it:value}{cmd:)} Maximum value of the distribution. Required with {opt type(6)}.{p_end}

{p 4 4 2}{opt group:ed} Compute grouped data on the fly (using {helpb alorenz}). It should only be used when unit records are provided.{p_end}

{p 4 4 2}{opt reg:ress} Display the Lorenz regression tables.{p_end}

{p 4 4 2}{opt bench:mark} Benchmark the parametric Lorenz estimates against direct estimates from the microdata (using {helpb apoverty} and {helpb ainequal}). This option is only allowed when using microdata with the original mean.{p_end}

{p 4 4 2}{opt unitrec:ord} Fit the parametric Lorenz curves on the unit records.{p_end}

{p 4 4 2}{opt nofig:ures} Omit the display of figures. By default, the Lorenz curve, PDF, and Pen's Parade figures are displayed.{p_end}

{p 4 4 2}{opt noe:lasticities} Omit the display of elasticities. By default, FGT(0), FGT(1) and FGT(2) elasticities with respect to the Mean and the Gini are reported.{p_end}

{p 4 4 2}{opt noc:hecks} Omit the display of consistency checks. By default, the internal consistency checks for both models are displayed. If the parametric Lorenz fails any of the checks, a warning will be displayed even if the {opt nochecks} option is selected.{p_end}

{p 4 4 2}{opt nol:orenz} Omit the table with the Lorenz curve. By default a table with the Lorenz curve is displayed.{p_end}

{p 4 4 2}{cmd:multiple} Additionally return scalars for each combination of mean and poverty line used, named {cmd:r(Hgq_}{it:pm}{cmd:)}, {cmd:r(PGgq_}{it:pm}{cmd:)}, ..., where {it:p} indexes the poverty line and {it:m} indexes the mean, together with one results matrix {cmd:r(results_}{it:pm}{cmd:)} per combination.{p_end}


{title:Saved Results}

{cmd:groupdata} returns results in {hi:r()} format.
By typing {helpb return list}, the following results are reported:

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{synopt:{cmd:r(zl)}}number of poverty lines specified{p_end}
{synopt:{cmd:r(zpl0)}}value of the first poverty line (zpl1, zpl2, ... for additional lines){p_end}
{synopt:{cmd:r(sd)}}standard deviation used{p_end}
{synopt:{cmd:r(mu)}}mean used{p_end}
{synopt:{cmd:r(bconverged)}}1 if the Beta Lorenz headcount solver converged within tolerance, 0 otherwise{p_end}

{p2col 7 20 24 2: Results GQ Lorenz Curve}{p_end}
{synopt:{cmd:r(Hgq)}}FGT0{p_end}
{synopt:{cmd:r(PGgq)}}FGT1{p_end}
{synopt:{cmd:r(SPGgq)}}FGT2{p_end}
{synopt:{cmd:r(GINIgq)}}Gini{p_end}

{p2col 7 20 24 2: Results Beta Lorenz Curve}{p_end}
{synopt:{cmd:r(Hb)}}FGT0{p_end}
{synopt:{cmd:r(PGb)}}FGT1{p_end}
{synopt:{cmd:r(SPGb)}}FGT2{p_end}
{synopt:{cmd:r(GINIb)}}Gini{p_end}

{p2col 7 20 24 2: Checks GQ Lorenz Curve}{p_end}
{synopt:{cmd:r(check1gq)}}L(0;pi)=0{p_end}
{synopt:{cmd:r(check2gq)}}L(1;pi)=1{p_end}
{synopt:{cmd:r(check3gq)}}L'(0+;pi)>=0{p_end}
{synopt:{cmd:r(check4gq)}}L''(p;pi)>=0 for p within (0,1){p_end}
{synopt:{cmd:r(t)}}value of the Lorenz intercept at L(1;pi)=1{p_end}

{p2col 7 20 24 2: Checks Beta Lorenz Curve}{p_end}
{synopt:{cmd:r(check1b)}}L(0;pi)=0 (automatically satisfied by the functional form){p_end}
{synopt:{cmd:r(check2b)}}L(1;pi)=1 (automatically satisfied by the functional form){p_end}
{synopt:{cmd:r(check3b)}}L'(0+;pi)>=0{p_end}
{synopt:{cmd:r(check4b)}}L''(p;pi)>=0 for p within (0,1){p_end}

{p2col 7 20 24 2: Estimated Elasticities (GQ Lorenz Curve)}{p_end}
{synopt:{cmd:r(elhmu)}}FGT0 with respect to the Mean{p_end}
{synopt:{cmd:r(elhgini)}}FGT0 with respect to the Gini{p_end}
{synopt:{cmd:r(elpgmu)}}FGT1 with respect to the Mean{p_end}
{synopt:{cmd:r(elpggini)}}FGT1 with respect to the Gini{p_end}
{synopt:{cmd:r(elspgmu)}}FGT2 with respect to the Mean{p_end}
{synopt:{cmd:r(elspggini)}}FGT2 with respect to the Gini{p_end}

{p2col 7 20 24 2: Estimated Elasticities (Beta Lorenz Curve)}{p_end}
{synopt:{cmd:r(elhmub)}}FGT0 with respect to the Mean{p_end}
{synopt:{cmd:r(elhginib)}}FGT0 with respect to the Gini{p_end}
{synopt:{cmd:r(elpgmub)}}FGT1 with respect to the Mean{p_end}
{synopt:{cmd:r(elpgginib)}}FGT1 with respect to the Gini{p_end}
{synopt:{cmd:r(elspgmub)}}FGT2 with respect to the Mean{p_end}
{synopt:{cmd:r(elspgginib)}}FGT2 with respect to the Gini{p_end}

{p2col 7 20 24 2: Coefficients GQ Lorenz Curve}{p_end}
{synopt:{cmd:r(agq)}}A{p_end}
{synopt:{cmd:r(bgq)}}B{p_end}
{synopt:{cmd:r(cgq)}}C{p_end}

{p2col 7 20 24 2: Coefficients Beta Lorenz Curve}{p_end}
{synopt:{cmd:r(theta)}}theta{p_end}
{synopt:{cmd:r(gama)}}gama{p_end}
{synopt:{cmd:r(delta)}}delta{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(zlines)}}list of the poverty lines used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}output matrix with nine columns:{p_end}

{p2col 5 20 24 2:}{cmd:povline}: value of the poverty line used.{p_end}
{p2col 5 20 24 2:}{cmd:seqpov}: sequence of the poverty line estimate.{p_end}
{p2col 5 20 24 2:}{cmd:seqmean}: sequence of the mean used.{p_end}
{p2col 5 20 24 2:}{cmd:mean}: value of the mean used.{p_end}
{p2col 5 20 24 2:}{cmd:sd}: value of the standard deviation used.{p_end}
{p2col 5 20 24 2:}{cmd:indicator}{p_end}
{synopt:}1 FGT 0{p_end}
{synopt:}2 FGT 1{p_end}
{synopt:}3 FGT 2{p_end}
{synopt:}4 Gini{p_end}
{synopt:}5 L(0;pi)=0{p_end}
{synopt:}6 L(1;pi)=1{p_end}
{synopt:}7 L'(0+;pi)>=0{p_end}
{synopt:}8 L''(p;pi)>=0 for p within (0,1){p_end}
{p2col 5 20 24 2:}{cmd:model}{p_end}
{synopt:}0 Unit Records{p_end}
{synopt:}1 GQ Lorenz Curve{p_end}
{synopt:}2 Beta Lorenz Curve{p_end}
{p2col 5 20 24 2:}{cmd:type}{p_end}
{synopt:}1 Estimated Value{p_end}
{synopt:}2 with respect to the Mean{p_end}
{synopt:}3 with respect to the Gini{p_end}
{synopt:}4 Checking for consistency of Lorenz curve estimation{p_end}
{p2col 5 20 24 2:}{cmd:value}: estimated value; for the consistency checks: -99 NA, 1 OK, 0 FAIL.{p_end}

{synopt:{cmd:r(data)}}data table with the distributional data used to estimate the parametric Lorenz (only returned with the {opt grouped} option):{p_end}
{p2col 5 20 24 2:}{cmd:percentile}{p_end}
{p2col 5 20 24 2:}{cmd:cumulative distribution of the variable of interest}{p_end}
{p2col 5 20 24 2:}{cmd:max value}{p_end}
{p2col 5 20 24 2:}{cmd:cumulative distribution of the weights}{p_end}
{p2col 5 20 24 2:}{cmd:cumulative mean of the variable of interest}{p_end}
{p2col 5 20 24 2:}{cmd:mean value of variable of interest}{p_end}

{pstd}{cmd:Important}: To guarantee precision, we recommend using {it:double} when exporting variables from matrices to the dataset.{p_end}


{title:Examples}

{p 8 12}{inp:. groupdata PV1_R [aw=WT2019] if cnt == "VNM", zl(317) bins(20) mean(336.45) grouped nofigures nolorenz}{p_end}

{p 8 12}{inp:. groupdata PV1_R [aw=WT2019] if cnt == "VNM", zl(317) bins(20) mean(336.45) grouped nofigures nolorenz noelasticities nochecks}{p_end}

{p 8 12}{inp:. groupdata mean_welfare [pw=pop_share], zl(200) mean(214.28) type(5) binvar(decile) nofigures}{p_end}


{title:References}

{p 4 4 2}Datt, Gaurav, 1998. "Computational Tools for Poverty Measurement and Analysis," FCND Discussion Paper 50, Washington, DC. DOI 10.22004/ag.econ.94862. {browse "https://ageconsearch.umn.edu/record/94862":(link to publication)}{p_end}

{p 4 4 2}World Bank. Poverty and Inequality Platform (PIP), the successor to PovcalNet. {browse "https://pip.worldbank.org":(link)}{p_end}

{p 4 4 2}Azevedo, Joao Pedro, and Shabana Mitra, 2014. "Global Poverty Estimation: Theoretical and Empirical Validity of Parametric Lorenz Curve Estimates and Revisiting Nonparametric Techniques," January 2014, prepared for the World Bank Global Poverty Monitoring Working Group. The methodological note behind this module: it sets out the four theoretical-validity conditions and reports that the GQ Lorenz curve fails at least one of them in 38% of the 69 surveys examined, and the Beta Lorenz curve in 93%. {browse "https://github.com/jpazvd/groupdata/blob/main/doc/grouped-global-poverty-2014-technical-note.pdf":(link to the note)}{p_end}

{title:ADO Dependencies}

{p 4 4 2}Joao Pedro Azevedo, 2006. "APOVERTY: Stata module to compute poverty measures," Statistical Software Components S456750, Boston College Department of Economics, revised 13 Apr 2007. {browse "https://ideas.repec.org/c/boc/bocode/s456750.html":(link)}{p_end}

{p 4 4 2}Joao Pedro Azevedo, 2006. "AINEQUAL: Stata module to compute measures of inequality," Statistical Software Components S456748, Boston College Department of Economics, revised 13 Apr 2007. {browse "https://ideas.repec.org/c/boc/bocode/s456748.html":(link)}{p_end}

{p 4 4 2}Joao Pedro Azevedo & Samuel Franco, 2006. "ALORENZ: Stata module to produce Pen's Parade, Lorenz and Generalised Lorenz curve," Statistical Software Components S456749, Boston College Department of Economics, revised 09 Jul 2012. {browse "https://ideas.repec.org/c/boc/bocode/s456749.html":(link)}{p_end}

{p 4 4 2}Paul Corral & Minh Cong Nguyen & Joao Pedro Azevedo, 2018. "GROUPFUNCTION: Stata module to replace several basic collapse functions," Statistical Software Components S458475, Boston College Department of Economics. {browse "https://ideas.repec.org/c/boc/bocode/s458475.html":(link)}{p_end}

{p 4 4 2}Daniel Klein, 2019. "WHICH_VERSION: Stata module to return location and programmer's version of ado-files," Statistical Software Components S458706, Boston College Department of Economics, revised 11 Nov 2019. {browse "https://ideas.repec.org/c/boc/bocode/s458706.html":(link)}{p_end}

{p 4 4 2}Ben Jann. "ESTOUT: Stata module to make regression tables." {browse "http://repec.sowi.unibe.ch/stata/estout/":(link)}{p_end}

{title:Keywords}

{p 4 4 2}Group Data; Parametrized Lorenz; Poverty Estimation; Pen's Parade; Lorenz; Generalized Lorenz{p_end}

{title:Authors}

{p 4 4 2}Joao Pedro Azevedo{p_end}
{p 4 4 2}World Bank{p_end}
{p 4 4 2}{browse "mailto:jazevedo@worldbank.org":jazevedo@worldbank.org}{p_end}
{p 4 4 2}{browse "http://www.worldbank.org/en/about/people/j/joao-pedro-azevedo":personal page}{p_end}

{p 4 4 2}Shabana Mitra{p_end}
{p 4 4 2}Senior Fellow, ICRIER; Associate Professor, Department of Economics, Shiv Nadar University{p_end}
{p 4 4 2}{browse "mailto:shabana.mitra@snu.edu.in":shabana.mitra@snu.edu.in}{p_end}
{p 4 4 2}{browse "https://sites.google.com/site/shabanamitra/":personal page}{p_end}
{p 4 4 2}Co-author of the original povcal.ado implementation on which this module is based.{p_end}

{title:Acknowledgements}

{p 4 4 2}Aziz Atamanov ({browse "https://github.com/azizatamanov":@azizatamanov}) for testing and bug reporting on the grouped-data estimation paths in 2020; the debugging session recorded in qa/aziz_groupdata.do surfaced a bug in the figures option.{p_end}

{p 4 4 2}The technical note behind this module thanks the members of the World Bank Global Poverty Working Group, in particular Shaohua Chen, Prem Sangraula, Nobuo Yoshida and Johan A. Mistiaen.{p_end}

{title:GitHub Repository}

{p 4 4 2}For the source code and previous releases please visit the GROUPDATA {browse "https://github.com/jpazvd/groupdata":GitHub repo}.{p_end}


{title:Also see}

{p 2 4 2}Online:  help for {help apoverty}; {help ainequal}; {help alorenz}; {help wbopendata}; {help mpovline}; {help drdecomp}; {help skdecomp}; {help tabmult}; {help xtsur} (if installed){p_end}
