# GROUPDATA: Stata module for poverty and inequality estimations using grouped data
 
Poverty rates at an international poverty line were originally estimated by first fitting a parametric Lorenz curve
to the grouped data and then using the functional relationship between the slope of the Lorenz curve and mean income to identify the headcount rate of poverty (World Bank 2021). The following relation when evaluated at the point representing the
proportion of the poor in the population, the slope is equal to the ratio of the international poverty line to
mean household expenditure (or income) per capita (see equation 1).

		𝐿′ (𝑝) = 𝑧/𝜇 at 𝑝 = 𝐻 							(1)
 
To calculate the slope of the Lorenz curve, the Lorenz curve is estimated using one of the following two
functional forms – the Beta Lorenz curve and the General Quadratic (GQ) Lorenz curve. For example, if
the Beta Lorenz Curve 𝐿(𝑝) = 𝑝 − 𝜃𝑝𝛾 (1 − 𝑝)𝛿 were used, three parameters 𝜃, 𝛾, and 𝛿 need to be
estimated. There are four conditions which need to be satisfied by the estimated parameters for the Lorenz
curve to be theoretically valid. There conditions are:

		1. 𝐿(0) = 0
		2. 𝐿(1) = 1
		3. 𝐿′(0+) ≥ 0
		4. 𝐿′′(𝑝) ≥ 0, 𝑝 ∈ (0,1)

The first two conditions, which may be called boundary conditions, imply that 0 and 100 percent of the
population account for 0 and 100 percent of the total income or expenditure, respectively. The third and
fourth conditions ensure that the Lorenz curve is monotonically increasing and convex. There is no
guarantee that the estimated parameters of the Lorenz curve will satisfy all these conditions.7
If the Beta Lorenz curve is adopted, equation (1) becomes:

		1 − 𝜃𝐻𝛾 (1 − 𝐻)𝛿 [(𝛾/𝐻) − (𝛿/(1−𝐻)] = (𝑧/𝜇) 		(2)
		
Equation (2) clearly indicates that if we have the three parameters of the Lorenz curve, the poverty line
and the mean household expenditure (or income), we can solve this equation to get the estimate of the
poverty headcount rate (H). Poverty gaps, severity of poverty, and Gini coefficients can also be calculated
from specific equations derived from the Lorenz curves (see also Datt 1998).

## References

[Datt, Gaurav, 1998. "Computational Tools for Poverty Measurement and Analysis," FCND Discussion Paper 50, Washington, DC. Doi 10.22004/ag.econ.94862](https://ageconsearch.umn.edu/record/94862)

[World Bank. 2021. Povcalnet.](http://iresearch.worldbank.org/PovcalNet/PovCalculator.aspx)

## ADO Dependencies

[Joao Pedro Azevedo, 2006. "APOVERTY: Stata module to compute poverty measures," Statistical Software Components S456750, Boston College Department of Economics, revised 13 Apr 2007.](https://ideas.repec.org/c/boc/bocode/s456750.html)

[Joao Pedro Azevedo, 2006. "AINEQUAL: Stata module to compute measures of inequality," Statistical Software Components S456748, Boston College Department of Economics, revised 13 Apr 2007.](https://ideas.repec.org/c/boc/bocode/s456748.html)

[Joao Pedro Azevedo & Samuel Franco, 2006. "ALORENZ: Stata module to produce Pen's Parade, Lorenz and Generalised Lorenz curve," Statistical Software Components S456749, Boston College Department of Economics, revised 09 Jul 2012.](https://ideas.repec.org/c/boc/bocode/s456749.html)

[Paul Corral & Minh Cong Nguyen & Joao Pedro Azevedo, 2018. "GROUPFUNCTION: Stata module to replace several basic collapse functions," Statistical Software Components S458475, Boston College Department of Economics.](https://ideas.repec.org/c/boc/bocode/s458475.html)

[Daniel Klein, 2019. "WHICH_VERSION: Stata module to return location and programmer's version of ado-files," Statistical Software Components S4584706, Boston College Department of Economics, revised 11 Nov 2019.](https://ideas.repec.org/c/boc/bocode/s458706.html)



#### Keywords: 
Group Data; Parametrized Lorenz; Poverty Estimation; Pen's Parade; Lorenz; Generalized Lorenz

## Authors: 

  **João Pedro Azevedo**  
  [jazevedo@worldbank.org](mailto:jazevedo@worldbank.org)  
  World Bank  
  [personal page](http://www.worldbank.org/en/about/people/j/joao-pedro-azevedo)  

  **Shabana Mitra**  
