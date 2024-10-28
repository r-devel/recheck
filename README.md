# recheck

Tools to run a reverse dependency check similar to CRAN.


## How to use with GitHub Actions

To use this on GitHub Actions you can simply call the [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows). To do this, create a new workflow in your package git repo named `.github/workflows/recheck.yml` which contains the following:

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
      subdirectory: '' #if your package is in a git subdir
```

Then trigger it manually using the 'run workflow' button under the actions tab. Note that you can pick a branch to test, so you can perform reverse dependency checks on a feature branch before merging into main.

A summary of the results can be seen in the GHA webUI. Upon completion, the full install/check logs for all packages are available in the 'artifacts' section.

See [Advanced Usage](#advanced-usage) for information on additional workflow arguments recheck supports.

## Real world example

See here for an example using the V8 package: https://github.com/jeroen/V8/actions/workflows/recheck.yaml


![example](https://github.com/user-attachments/assets/9f5f67fc-a0aa-444b-a5a6-e3afad12a354)


## Recheck goals and limitations

A reverse dependency check can be a useful diagnostic tool to identify potential regressions that may need further investigation. However it is often impractical to use as a red/green CI test: checks from other packages that depend on yours can be influenced by all sorts of factors specific to the platform, hardware, network, system setup, or just random failures.

The goal of this repo is to provide a simple tool that can run on free infrastructure to discover potential problems with reverse dependencies of your package. However it is still up to you to interpret the results, and possibly investigate them to identify problems. We try to create a setup similar to CRAN, but we need to make trade offs to keep this practical (see below).

## Important caveats

To be able check reverse dependencies, we first need to install all dependencies (including Suggests) for each of those packages. Many CRAN packages indirectly depend on 100+ other packages, so this quickly adds up. 

Hence even if your package only has a handful of dependents, you may need to install over a thousand other packages, before even starting the revdep check. For this reason it is only practical to do this on a platforms for which precompiled R binary packages are available.

CRAN runs revdep checks on `r-devel` on a server with `debian:testing` but there are currently no R binary packages available for this platform. Instead our containers are based on `ubuntu:latest` and run `r-release`, for which public binary packages are available via https://p3m.dev and https://r-universe.dev. This is one reason results might be slighlty different from what CRAN would show, though in practice it is usually irrelevant.

## On rcheckserver

On GitHub actions we run the check inside the [rcheckserver](https://github.com/r-devel/rcheckserver)
container. This container has the same system libraries installed as the CRAN Debian server.

## Advanced Usage

By default, recheck runs against the package in the current repository.
For some use cases, it may be useful to run recheck against a repository other than the current one and/or against a branch other than the default.

This can be achieved through a combination of the `repo` and `ref` parameters:

- `repo`: Repository to checkout (as `owner/repo`)
- `ref`: The branch, tag or SHA to checkout

See the following example to get an idea of what this can look like:

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
      subdirectory: 'r'
      repo: user/package_name
      ref: my_branch
```

The above workflow runs recheck on the `my_branch` branch of a clone of https://github.com/user/package_name.
