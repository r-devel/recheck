# recheck

Experimental workflow to run a reverse dependency check similar to CRAN.


## How to use

This is set up as a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows). To trigger it, add a workflow in your own package git repo named `.github/workflows/recheck.yml` that contains:

```
on:
  workflow_dispatch:
# push:

name: Run a recheck

jobs:
  recheck:
    uses: r-devel/recheck/.github/workflows/recheck.yml@v1
```

And then trigger it from the actions tab.

