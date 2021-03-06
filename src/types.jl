abstract type Optimizer end
function print_header(method::Optimizer)
    @printf "Iter     Function value   Gradient norm \n"
end

immutable Options{TCallback <: Union{Void, Function}}
    x_tol::Float64
    f_tol::Float64
    g_tol::Float64
    f_calls_limit::Int
    g_calls_limit::Int
    h_calls_limit::Int
    allow_f_increases::Bool
    iterations::Int
    store_trace::Bool
    show_trace::Bool
    extended_trace::Bool
    show_every::Int
    callback::TCallback
    time_limit::Float64
end
function Options(;
        x_tol::Real = 1e-32,
        f_tol::Real = 1e-32,
        g_tol::Real = 1e-8,
        f_calls_limit::Int = 0,
        g_calls_limit::Int = 0,
        h_calls_limit::Int = 0,
        allow_f_increases::Bool = false,
        iterations::Integer = 1_000,
        store_trace::Bool = false,
        show_trace::Bool = false,
        extended_trace::Bool = false,
        show_every::Integer = 1,
        callback = nothing,
        time_limit = NaN)
    show_every = show_every > 0 ? show_every: 1
    #if extended_trace && callback == nothing
    #    show_trace = true
    #end
    Options{typeof(callback)}(
        Float64(x_tol), Float64(f_tol), Float64(g_tol), f_calls_limit, g_calls_limit, h_calls_limit,
        allow_f_increases, Int(iterations), store_trace, show_trace, extended_trace,
        Int(show_every), callback, time_limit)
end
function print_header(options::Options)
    if options.show_trace
        @printf "Iter     Function value   Gradient norm \n"
    end
end

immutable OptimizationState{T <: Optimizer}
    iteration::Int
    value::Float64
    g_norm::Float64
    metadata::Dict
end
function Base.show(io::IO, t::OptimizationState)
    @printf io "%6d   %14e   %14e\n" t.iteration t.value t.g_norm
    if !isempty(t.metadata)
        for (key, value) in t.metadata
            @printf io " * %s: %s\n" key value
        end
    end
    return
end

OptimizationTrace{T} = Vector{OptimizationState{T}}
function Base.show(io::IO, tr::OptimizationTrace)
    @printf io "Iter     Function value   Gradient norm \n"
    @printf io "------   --------------   --------------\n"
    for state in tr
        show(io, state)
    end
    return
end

abstract type OptimizationResults end
type UnivariateOptimizationResults{T,O<:Optimizer} <: OptimizationResults
    method::O
    initial_lower::T
    initial_upper::T
    minimizer::T
    minimum::T
    iterations::Int
    iteration_converged::Bool
    converged::Bool
    rel_tol::T
    abs_tol::T
    trace::OptimizationTrace{O}
    f_calls::Int
end
type MultivariateOptimizationResults{O<:Optimizer,T,N} <: OptimizationResults
    method::O
    initial_x::Array{T,N}
    minimizer::Array{T,N}
    minimum::T
    iterations::Int
    iteration_converged::Bool
    x_converged::Bool
    x_tol::Float64
    x_residual::Float64
    f_converged::Bool
    f_tol::Float64
    f_residual::Float64
    g_converged::Bool
    g_tol::Float64
    g_residual::Float64
    f_increased::Bool
    trace::OptimizationTrace{O}
    f_calls::Int
    g_calls::Int
    h_calls::Int
end
function Base.append!(a::MultivariateOptimizationResults, b::MultivariateOptimizationResults)
    a.iterations += iterations(b)
    a.minimizer = minimizer(b)
    a.minimum = minimum(b)
    a.iteration_converged = iteration_limit_reached(b)
    a.x_converged = x_converged(b)
    a.f_converged = f_converged(b)
    a.g_converged = g_converged(b)
    append!(a.trace, b.trace)
    a.f_calls += f_calls(b)
    a.g_calls += g_calls(b)
end
