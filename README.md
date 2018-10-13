# DeIdentification.jl

[![Build Status](https://travis-ci.org/paulstey/DeIdentficiation.jl.svg?branch=master)](https://travis-ci.org/paulstey/DeIdentficiation.jl)

[![Coverage Status](https://coveralls.io/repos/paulstey/DeIdentficiation.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/paulstey/DeIdentficiation.jl?branch=master)

[![codecov.io](http://codecov.io/github/paulstey/DeIdentficiation.jl/coverage.svg?branch=master)](http://codecov.io/github/paulstey/DeIdentficiation.jl?branch=master)



# Installation
```julia
Pkg.clone("https://github.com/bcbi/DeIdentification.jl.git")
```

<!-- # Important Notes
There are a few subtle points that must be kept in mind when using this package. These are discussed below.

## Date Shifting.
In the current implementation, date shifting is done by selecting a random random integer, _d_, between -_N_ and _N_. Where _N_ is a user-specified argument in the YAML file (or otherwise, passed directly to the `DeIdDataFrame()` constructor). -->
