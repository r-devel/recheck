# recheck

Run a reverse dependency check similar to CRAN.

## How to use with GitHub Actions

We prepared a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows) that you can easily run for free on GitHub Actions. To do this, create a new workflow file in your package git repo named `.github/workflows/recheck.yml` which contains the following:

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
      subdirectory: '' # set if your R package is in a subdir of the git repo
      repository: '' # set to recheck an R package from another git repo
      ref: '' # set to recheck a custom tag/branch from another repo
```

After committing this file, you can trigger it using the 'run workflow' button under the actions tab. Note that you can pick a target branch in this UI, so you can perform the reverse dependency checks on a feature branch.

A summary of the results can be seen in the GHA webUI. Upon completion, the full install/check logs for all packages are available in the 'artifacts' section.

The `repository` and `ref` parameters are only needed if you want to recheck a package from another git repository than the one that has the workflow.

## Real world example

See here for an example using the V8 package: https://github.com/jeroen/V8/actions/workflows/recheck.yaml


![example](https://github.com/user-attachments/assets/9f5f67fc-a0aa-444b-a5a6-e3afad12a354)


## Recheck goals and limitations

A reverse dependency check can be a helpful diagnostic tool to identify potential regressions that may need investigation. However it is typically too volatile to use as an automatic pass/fail CI test: checks results from other packages can be influenced by all sorts of factors specific to the platform, hardware, network, system setup, or just random failures.

The goal of this repo is to provide a simple tool that can run on free infrastructure to discover potential problems with reverse dependencies of your package. It is still up to you to interpret the results. We try to create a setup similar to CRAN, but we need to make trade offs to keep this practical (see below).

## Important caveats

To be able check reverse dependencies, we first need to install all dependencies (including Suggests) for each of those packages. Many CRAN packages indirectly depend on 100+ other packages, so this quickly adds up. 

Hence even if your package only has a handful of dependents, you may need to install over a thousand other packages, before even starting the revdep check. For this reason it is only practical to do this on a platforms for which precompiled R binary packages are available.

CRAN runs revdep checks on `r-devel` on a server with `debian:testing` but there are currently no R binary packages available for this platform. Instead our containers are based on `ubuntu:latest` and run `r-release`, for which public binary packages are available via https://p3m.dev and https://r-universe.dev. This is one reason results might be slighlty different from what CRAN would show, though in practice it is usually irrelevant.

It is also not the goal of this repo to support every possible flag in `CMD check`

## On rcheckserver

On GitHub actions we run the check inside the [rcheckserver](https://github.com/r-devel/rcheckserver)
container. This container has the same system libraries installed as the CRAN Debian server.
