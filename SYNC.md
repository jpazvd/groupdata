# How this repository is maintained

`jpazvd/groupdata` is the **distribution** repository. It is what
`net install` serves, and it is a one-way mirror of a subset of a private
development repository.

Development, testing and issue tracking happen upstream. This repository
receives only the files needed to install and understand the package.

## Branches

| Branch | Purpose |
| :--- | :--- |
| `main` | The released package. This is what `net install` serves. Do not install from anything else. |
| `dev` | Staging for the next release. Mirrors the upstream `dev` branch. Content here may change or be withdrawn. |

Releases are tagged on `main`.

## Releases and tags

| Tag | What it is |
| :--- | :--- |
| `v3.4` and later | Normal releases. Tagged on `main`, installable with `net install`. |
| `v2.9` | A **source archive**, not a release you can install. |

`v2.9` predates the `net install` packaging, which arrived in v3.0 (April
2021): it has no `stata.toc` and no `groupdata.pkg`, and none has been
back-fitted, because that would ship metadata which never existed. Its commit
has no parent — this repository was created in 2026 and does not carry the
2020 development history — and its `qa/` folder is omitted for the reason
given above. Commit and tag dates are the originals. See `ARCHIVE-NOTICE.md`
on that tag.

Releases between v2.9 and v3.4 exist only in the upstream repository.

## What is synced here

Only the files below are copied from upstream. Everything else stays private.

**Required — `net install` does not work without these:**

| Path | Why |
| :--- | :--- |
| `stata.toc` | `net from` fails without it |
| `groupdata.pkg` | the package manifest |
| `src/groupdata.ado` | the command |
| `src/groupdata.sthlp` | the help file |
| `dependency.do` | named in the manifest, so a missing copy breaks `net install` |

**User-facing:**

| Path | Why |
| :--- | :--- |
| `README.md` | landing page |
| `CHANGELOG.md` | release history |
| `LICENSE` | MIT |
| `doc/*.pdf` | the technical note; the help file links it by URL |
| `.gitattributes` | keeps LF line endings on the shipped `.ado` and `.sthlp` |
| `SYNC.md` | this file |

## What is deliberately not synced

| Path | Why it stays private |
| :--- | :--- |
| `qa/` | ~75 MB of derived assessment microdata, plus QA and certification scripts |
| `tests/` | development tooling and the regression suite |
| `.github/workflows/` | CI that references paths which do not exist here |
| `TODO.md` | internal roadmap; it records defects that are not yet fixed |
| `CONTRIBUTING.md` | describes a branch model and test suites that only exist upstream |
| `_archive/` | superseded material kept upstream for reference |

That is roughly 460 KB here against ~76 MB upstream.

## Consequences worth knowing

- **The help file and README may reference paths that do not exist here.**
  For example `qa/aziz_groupdata.do` is named in the Acknowledgements but is
  not synced. Such references are plain text, never links.
- **`groupdata.pkg` must never list a file that is not synced.** If it does,
  `net install` fails for everyone. The manifest is validated upstream against
  the upstream tree, not against this one, so this is checked by hand at
  publish time.
- **Issues and pull requests opened here** will be read, but changes are made
  upstream and arrive by sync. A PR against this repository cannot be merged
  as-is.

## Installing

```stata
net install groupdata, from("https://raw.githubusercontent.com/jpazvd/groupdata/main/") replace
```

Then install the user-written dependencies:

```stata
findfile dependency.do
do "`r(fn)'"
```

`groupdata` also installs any missing dependency at runtime, so that step is a
convenience rather than a requirement.
