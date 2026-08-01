# Changelog

All notable changes to the `groupdata` Stata module. The authoritative
version history also lives at the bottom of `src/groupdata.ado`.

## [3.3] - 2026-08-01

### Fixed
- **`r(GINIgq)` did not return the GQ Lorenz Gini.** It returned `gini_ln`, a
  lognormal expression, and so did row 4 of `r(results)` (which was even named
  `gini_ln` while sitting in the GQ block next to `H`, `PG` and `SPG`). The
  GQ Gini was computed correctly as `gini_tt` and then discarded. On the
  certification fixture the command reported `-0.676` — outside [0,1] and
  therefore impossible — where the GQ Lorenz Gini is `0.1339`. Row 4 is now
  `gini_tt`, renamed `GiniGQ` to parallel `GiniBeta`.

  Validated three ways on `qa/score2017.dta` (grade 5): the analytic GQ formula
  gives `0.133912`, numerical integration of `L(p)` over [0,1] gives
  `0.133911`, and the microdata Gini from `ainequal` is `0.133982`. The GQ
  estimate is now closer to the microdata than the Beta estimate
  (`0.000070` vs `0.000115`). The fitted curve itself was never at fault:
  `L(0) = 0` and `L(1) = 1` hold exactly, `L'(p) >= 0.494` and
  `L''(p) >= 0.616` across [0,1].
- `multiple` aborted with `r(503)` and corrupted every poverty line after the
  first. The sample moments were measured inside the `foreach z in zl()` loop,
  but the loop body reduces the data to the grouped bins (`keep if pg != .`),
  so later iterations summarised the bins instead of the estimation sample: the
  reported mean fell from 214.28 to 92.06 and `FGT(0)` reached 109.61. The
  moments are now measured once, before the loop. `multiple` with
  `zl(180 200 220)` now reproduces the three single-line calls exactly.
- Stray double `in` range qualifiers (``in 2/l`` followed by a second
  ``in 2/`bins'``) in the grouped-data
  branches. Stata rejects a second `in` with `r(198)`, so `type(2)` (which
  accepts only aweights), `type(5)` with fweights, and `type(6)` without
  weights aborted for every caller. Verified against Stata 17.
- `type(5)` with fweights: the Lorenz share divided an *unweighted* income by a
  *population-weighted* total, so the ordinates did not reach 1. The numerator
  is now weighted by the bin population.
- `weight2` was left empty when the caller supplied no weights, so the
  per-type weight checks tested an empty string against the synthesised
  fweight.
- The `which_version` dependency checks now run under `capture`; a missing
  `which_version` no longer aborts the command.
- `type()` option validation: an empty `type()` was treated as a valid match,
  which made the `grouped` option (and unit-record calls) fail validation with
  a misleading error; validation now uses `inlist()`.
- `gen doulbe` typo that broke `type(5)` with fweights.
- Inverted display of the Beta Lorenz condition-4 consistency check (printed
  OK on failure and FAIL on success, contradicting the returned `r(check4b)`).
- Chained inequalities in the GQ Lorenz condition-4 check (Stata evaluates
  `0 < m < x` left-to-right); rewritten as explicit conjunctions.
- Undefined macro (`coefbgq`) and operator precedence in the coefficient-vector
  validation.
- Figures referenced the poverty line before it was defined; they now use the
  first line in `zl()` for their reference lines.
- `set obs` guard for the 32-row output matrix failed with 24-31 observations.
- User-supplied `sd()` is no longer overwritten by the sample standard
  deviation.
- The caller's random-number generator state is preserved and restored
  (previously the command permanently reseeded the RNG); `uniform()` replaced
  by `runiform()`.
- Duplicated row names (`check3*`/`check4*`) in the returned results matrix.
- `type(6)` without weights: the bin-midpoint adjustment used the range
  `1/bins`, overwriting the first bin's delta (set from `min()`) with a
  missing value and corrupting the Lorenz ordinates; now `2/last`, matching
  the pw/fw branches.

### Added
- `r(N)`: number of observations used (documented but previously not
  returned).
- Validation of `bins()` (minimum of 4) and an explicit error when no
  estimation mode (`grouped`, `unitrecord`, `type()`, or
  `coefb()`/`coefgq()`) is selected.
- `r(bconverged)`: convergence flag for the Beta Lorenz headcount solver,
  which is also now documented in the code.

### Changed
- Deduplicated the byte-identical benchmark loop branches and
  grouped/non-grouped return blocks.
- The dependency check now installs missing commands once each and runs the
  groupfunction/alorenz version checks once per call instead of once per
  installed command.

### Removed
- Unreachable code paths (`gini_G`, `nsmean`, `npovline`).

## [3.2] - 2022-03-01
- Add check for when the grouped data option is enabled.
- Clarify help file: the grouped option should only be used when unit records
  are provided.

## [3.1] - 2021-04-16
- Fix bug on the display of the Lorenz table.
- `debug` is an undocumented option.

## [3.0] - 2021-04-13
- Add `multiple` option: multiple estimates are now stored as scalars.
- Fix bugs on the reporting of elasticities.
- Improve the help file.

## [2.9] - 2020-06-16
- Remove typo in line 643.

## [2.8] - 2020-04-28
- Support welfare estimations based on provided coefficients.
- Add multiple mean options.
- Add debug milestones.
- Return matrix includes mean, sd, and poverty line.

## [2.7] - 2020-04-24
- Fix estimates using unit record data.
- Estimate multiple poverty lines.

## [2.6] - 2020-04-16
- Add Beta and Quadratic Lorenz regression coefficients to the return list.

## [2.5] - 2020-04-14
- Add the `cleanversion` helper function.

## [2.4] - 2020-04-10
- Fix `lnsd`.
- Multiple poverty lines (`mz`) and multiple mean values (`mmu`).

## [2.3.1] - 2020-04-08
- Add `sd()` as an option when estimating grouped data.
- Remove pweights where not supported by `summarize`.
- Document grouped-data types 1, 2, 5, 6 and unit-record data.
- Improve the layout.

## [2.2] - 2020-04-06
- Dependency checks run quietly.
- `apoverty` and `ainequal` added to the dependency checks.

## [2.1] - 2020-04-05
- Rename the command from `grouppov` to `groupdata`.

## [2.0] - 2020-04-02
- Changes made to use this method to estimate learning poverty.
- Add support for aweights.
- Replace `wtile2` with `alorenz`.
- Add microdata values as benchmark.

## [1.1] - 2014-01-14
- Rename from `povcal` to `grouppov`.
- Technical note on Global Poverty Estimation: Theoretical and Empirical
  Validity of Parametric Lorenz Curve Estimates and Revisiting Non-parametric
  Techniques (January 2014), for discussions of the World Bank Global Poverty
  Monitoring Working Group.

## [1.0] - 2012-02-02
- `povcal.ado` created by Joao Pedro Azevedo (JPA) and Shabana Mitra (SM).
