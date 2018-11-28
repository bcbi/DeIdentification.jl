# DeIdentification.jl

[![Build Status](https://travis-ci.org/bcbi/DeIdentficiation.jl.svg?branch=master)](https://travis-ci.org/bcbi/DeIdentficiation.jl)

[![codecov.io](http://codecov.io/github/bcbi/DeIdentficiation.jl/coverage.svg?branch=master)](http://codecov.io/github/bcbi/DeIdentficiation.jl?branch=master)



# 1. Installation
```julia
Pkg.add("https://github.com/bcbi/DeIdentification.jl.git")
```

<!-- # Important Notes
There are a few subtle points that must be kept in mind when using this package. These are discussed below.

## Date Shifting.
In the current implementation, date shifting is done by selecting a random random integer, _d_, between -_N_ and _N_. Where _N_ is a user-specified argument in the YAML file (or otherwise, passed directly to the `DeIdDataFrame()` constructor). -->
