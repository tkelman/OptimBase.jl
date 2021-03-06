module OptimBase


using Reexport
@reexport using NLSolversBase

import Base.summary

export OptimizationOptions,
       OptimizationState,
       OptimizationTrace,
       Optimizer,
       UnivariateOptimizationResults,
       MultivariateOptimizationResults,
       # API
       minimizer,
       converged


include("types.jl")
include("api.jl")

end # module
