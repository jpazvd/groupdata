# v2.9 — source archive, not installable

This tag is a **retrospective publication of the v2.9 source as it stood on
16 June 2020**. It is not part of the release line this repository serves.

## It cannot be installed

v2.9 predates the `net install` packaging, which arrived in v3.0 (April 2021).
There is no `stata.toc` and no `groupdata.pkg` here, so

```stata
net install groupdata, from(".../v2.9/")
```

will not work, and no packaging has been back-fitted to make it work — doing so
would ship metadata that never existed in 2020.

To use the package, install the current release from `main`.

## What is here, and what is not

Present: `src/groupdata.ado`, `src/groupdata.sthlp`, `README.md`, `LICENSE`,
`dependency.do` and the technical note, exactly as at v2.9.

Absent: the `qa/` folder. Upstream it holds roughly 75 MB of derived assessment
microdata, which is not mirrored to this repository. Its absence is deliberate,
not an omission from the original.

## Why the commit stands alone

This repository was created in 2026 as a distribution mirror and does not carry
the 2020 development history. The commit this tag points at therefore has no
parent. The full history lives in the private development repository.

## Known defects in this version

v2.9 contains bugs fixed in v3.3 and v3.4, including `r(GINIgq)` returning a
lognormal expression rather than the GQ Lorenz Gini. See `CHANGELOG.md` on
`main`. Do not use this version for estimation.
