# recheck

Experimental workflow to run a reverse dependency check similar to CRAN.


## How to use

This is set up as a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows). To use this create a workflow in your package git repo named `.github/workflows/recheck.yml` which contains:

```yml
on:
  workflow_dispatch:
    inputs:
      which:
        type: choice
        description: Which dependents to check
        options:
        - strong
        - most

name: Reverse dependency check

jobs:
  revdep_check:
    name: Reverse check ${{ inputs.which }} dependents
    uses: r-devel/recheck/.github/workflows/recheck.yml@v1
    with:
      which: ${{ inputs.which }}
```

Then trigger it manually using the 'run workflow' button under the actions tab.

## Goals and limitations

A reverse dependency check is not a red/green CI test. You should see it more as a diagnostic tool to identify potential issues that may need further investigation.

Checks from other packages that depend on yours are influenced by all sorts of factors specific to the platform, hardware, network, system setup, or just random failures. We try to create a setup similar to CRAN, but we need to make trade offs to keep this practical.

The goal is to provide a simple tool that can run on free infrastructure to check for potential problems with reverse dependencies of your package. It is still up to you to interpret the results, and possibly compare and investigate them to identify regressions.

## Important caveats

To be able check reverse dependencies, we first need to install all dependencies (including Suggests) for each of those packages. Many CRAN packages indirectly depend on 100+ other packages, so this quickly adds up. 

Even if your package only has a handful of dependents, you may need to install over a thousand other packages, before even starting the revdep check. For this reason it is only practical to do this in GHA on a platforms for which precompiled R binary packages are available.

CRAN runs revdep checks on `r-devel` on a server with `debian:testing` but there are currently no public binary packages available for this platform. Instead our containers are based on `ubuntu:latest` and run `r-release`, for which public binary packages are available via https://p3m.dev and https://r-universe.dev. This is one reason results might be slighlty different from what CRAN would show, though in practice it is rarely an issue.


## On rcheckserver

On GitHub actions we run the check inside the [rcheckserver](https://github.com/r-devel/rcheckserver)
container. This container has the same system libraries installed as the CRAN Debian server.
