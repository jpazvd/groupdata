# GROUPDATA: Stata module for poverty and inequality estimation using grouped data

`groupdata` estimates poverty (FGT0, FGT1, FGT2) and inequality (Gini) measures by fitting parametric Lorenz curves — the General Quadratic (GQ) and the Beta Lorenz curves — to grouped (binned) distributional data or to unit-record data. It implements the approach of Datt (1998) originally used by the World Bank's PovcalNet (now the [Poverty and Inequality Platform](https://pip.worldbank.org)) for global poverty monitoring. It also reports the elasticities of each poverty measure with respect to the mean and the Gini, and the theoretical-validity checks of the fitted Lorenz curves.

## Installation

Install directly from GitHub:

```stata
net install groupdata, from("https://raw.githubusercontent.com/jpazvd/groupdata/main/") replace
```

Then install the user-written dependencies. `dependency.do` ships with the
package, so after installing you can run it directly:

```stata
findfile dependency.do
do "`r(fn)'"
```

Or install them by hand:

```stata
ssc install apoverty
ssc install ainequal
ssc install alorenz
ssc install groupfunction
ssc install which_version
ssc install estout
```

`groupdata` also installs any missing dependency at runtime, so this step is a
convenience rather than a requirement.

## Quick start

```stata
* Unit-record data: build 20 bins on the fly and estimate at poverty line 200
groupdata welfare [aw=weight], zl(200) grouped nofigures

* Same, benchmarking the parametric estimates against the microdata
groupdata welfare [aw=weight], zl(200) grouped benchmark bins(20) nofigures

* Type 5 grouped data (bin means), with the distribution mean supplied
groupdata mean_welfare [pw=pop_share], zl(200) mean(214.28) type(5) binvar(decile) nofigures
```

`groupdata` supports the grouped-data types used by PovcalNet:

| Type | Welfare variable                      | Weight                                              |
| :--- | :------------------------------------ | :-------------------------------------------------- |
| 1    | L: cumulative share of income/welfare | P: cumulative population share (`aweight`)          |
| 2    | R: income/welfare share of the bin    | Q: population share of the bin (`aweight`)          |
| 5    | X: mean income/welfare of the bin     | W: population share (`pweight`, `fweight`, or none) |
| 6    | X: maximum income/welfare of the bin  | W: population share (`pweight`, `fweight`, or none) |

See `help groupdata` for the full syntax, options, and saved results.

## Methodology

Poverty rates at an international poverty line were originally estimated by first fitting a parametric Lorenz curve $L(p)$ to grouped data and then using the functional relationship between the slope of the Lorenz curve and mean income to identify the headcount rate of poverty. Evaluated at the point $p = H$ representing the proportion of poor in the population, the slope of the Lorenz curve equals the ratio of the poverty line $z$ to mean household expenditure (or income) per capita $\mu$:

$$
L'(p) = z/\mu \quad \text{at} \quad p = H \qquad (1)
$$

The Lorenz curve is estimated using one of two functional forms — the Beta Lorenz curve and the General Quadratic (GQ) Lorenz curve. For example, if the Beta Lorenz curve $L(p) = p - \theta p^{\gamma}(1-p)^{\delta}$ is used, three parameters $\theta$, $\gamma$, and $\delta$ need to be estimated. Four conditions must be satisfied for the estimated Lorenz curve to be theoretically valid:

1. $L(0) = 0$
2. $L(1) = 1$
3. $L'(0^{+}) \geq 0$
4. $L''(p) \geq 0, \quad p \in (0,1)$

The first two (boundary) conditions imply that 0 and 100 percent of the population account for 0 and 100 percent of the total income or expenditure, respectively. The third and fourth conditions ensure that the Lorenz curve is monotonically increasing and convex. There is no guarantee that the estimated parameters will satisfy all these conditions, so `groupdata` checks and reports each of them.

If the Beta Lorenz curve is adopted, equation (1) becomes:

$$
1 - \theta H^{\gamma}(1-H)^{\delta}\left[\frac{\gamma}{H} - \frac{\delta}{1-H}\right] = \frac{z}{\mu} \qquad (2)
$$

Given the three parameters of the Lorenz curve, the poverty line, and the mean household expenditure (or income), equation (2) can be solved for the estimate of the poverty headcount rate $H$. Poverty gaps, severity of poverty, and Gini coefficients are calculated from specific expressions derived from the fitted Lorenz curves (see Datt 1998).

For a fuller discussion, see the [technical note](doc/grouped-global-poverty-2014-technical-note.pdf) prepared for the World Bank Global Poverty Monitoring Working Group.

## References

- [Azevedo, João Pedro, and Shabana Mitra (2014). "Global Poverty Estimation: Theoretical and Empirical Validity of Parametric Lorenz Curve Estimates and Revisiting Nonparametric Techniques." January 2014. Prepared for the World Bank Global Poverty Monitoring Working Group.](doc/grouped-global-poverty-2014-technical-note.pdf) — the methodological note behind this module. It sets out the four theoretical-validity conditions the fitted Lorenz curve must satisfy, and reports that across 69 surveys from 19 Latin American and Caribbean countries (1995–2010) the GQ Lorenz curve fails at least one condition in 38% of cases and the Beta Lorenz curve in 93%.
- [Datt, Gaurav (1998). "Computational Tools for Poverty Measurement and Analysis." FCND Discussion Paper 50, Washington, DC. DOI 10.22004/ag.econ.94862](https://ageconsearch.umn.edu/record/94862)
- [World Bank. Poverty and Inequality Platform (PIP)](https://pip.worldbank.org) — the successor to PovcalNet.

## ADO dependencies

- [Joao Pedro Azevedo (2006). "APOVERTY: Stata module to compute poverty measures." Statistical Software Components S456750, Boston College Department of Economics, revised 13 Apr 2007.](https://ideas.repec.org/c/boc/bocode/s456750.html)
- [Joao Pedro Azevedo (2006). "AINEQUAL: Stata module to compute measures of inequality." Statistical Software Components S456748, Boston College Department of Economics, revised 13 Apr 2007.](https://ideas.repec.org/c/boc/bocode/s456748.html)
- [Joao Pedro Azevedo & Samuel Franco (2006). "ALORENZ: Stata module to produce Pen's Parade, Lorenz and Generalised Lorenz curve." Statistical Software Components S456749, Boston College Department of Economics, revised 09 Jul 2012.](https://ideas.repec.org/c/boc/bocode/s456749.html)
- [Paul Corral, Minh Cong Nguyen & Joao Pedro Azevedo (2018). "GROUPFUNCTION: Stata module to replace several basic collapse functions." Statistical Software Components S458475, Boston College Department of Economics.](https://ideas.repec.org/c/boc/bocode/s458475.html)
- [Daniel Klein (2019). "WHICH_VERSION: Stata module to return location and programmer's version of ado-files." Statistical Software Components S458706, Boston College Department of Economics, revised 11 Nov 2019.](https://ideas.repec.org/c/boc/bocode/s458706.html)
- [Ben Jann. "ESTOUT: Stata module to make regression tables."](http://repec.sowi.unibe.ch/stata/estout/) (`ssc install estout`)

## Authors

**João Pedro Azevedo**
World Bank
[jazevedo@worldbank.org](mailto:jazevedo@worldbank.org)
[personal page](http://www.worldbank.org/en/about/people/j/joao-pedro-azevedo)

**Shabana Mitra**
Senior Fellow, ICRIER; Associate Professor, Department of Economics, Shiv Nadar University
[shabana.mitra@snu.edu.in](mailto:shabana.mitra@snu.edu.in)
[personal page](https://sites.google.com/site/shabanamitra/)
Co-author of the original `povcal.ado` implementation on which this module is based.

## Acknowledgements

**Aziz Atamanov** ([@azizatamanov](https://github.com/azizatamanov)) — testing and bug reporting on the grouped-data estimation paths in 2020. The debugging session recorded in `qa/aziz_groupdata.do` surfaced a bug in the `figures` option, and he contributed a fix to that script.

The technical note behind this module thanks the members of the World Bank Global Poverty Working Group, in particular Shaohua Chen, Prem Sangraula, Nobuo Yoshida and Johan A. Mistiaen.

## Citation

If you use `groupdata` in your research, please cite:

> Azevedo, João Pedro, and Shabana Mitra. *GROUPDATA: Stata module for poverty and inequality estimation using grouped data.* https://github.com/jpazvd/groupdata

## License

Released under the [MIT License](LICENSE).

## Keywords

Grouped data; parametrized Lorenz; poverty estimation; Pen's Parade; Lorenz; generalized Lorenz
