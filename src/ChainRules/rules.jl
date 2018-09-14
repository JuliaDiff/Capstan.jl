#####
##### `rule`
#####
# Pros vs. DiffRules:
#   - way cleaner to human-read/write
#   - downstream cache invalidation is handled by world age mechanism
#   - this allows "direct computation" using the rules, without extra codegen
#
# Cons vs. DiffRules:
#   - not useful for symbolic differentiation (i.e. lazy differentiation of non-Julia code)
#   - many desirable transformations would require aggressive IPO/inlining
#     from the Julia compiler and/or LLVM than may be enabled by default
#
# This form is more desirable than DiffRules so long as we don't care about
# symbolic differentiation (i.e. lazy differentiation of non-Julia code), and
# we think that there aren't many compiler passes that a) are AD-specific, b)
# require callsite-specific information.

struct NoRule end

forward_rule(::Signature, ::Any, ::Vararg{Any}) = NoRule()

reverse_rule(::Signature, ::Any, ::Vararg{Any}) = NoRule()

# forward_chain(dfdx, dx) = dfdx .* dx
# forward_chain(dfdx, dx, dfdy, dy) = dfdx .* dx .+ dfdy .* dy
# forward_chain(dfdx, dx, dfdy, dy, dfdz, dz) = dfdx .* dx .+ dfdy .* dy .+ dfdz .* dz
# forward_chain(dfdx, dx, dfdy, dy, dfdz, dz, rest...) = forward_chain(dfdx, dx, dfdy, dy, dfdz, dz) .+ forward_chain(rest...)

#=
TODO: Develop these kinds of properties as their use cases arise

#####
##### `AbstractLinearity`
#####

abstract type AbstractLinearity end

struct Linear <: AbstractLinearity end

struct Nonlinear <: AbstractLinearity end

struct PiecewiseLinear <: AbstractLinearity end

linearity(::Func, ::Any) = Nonlinear()

#####
##### `AbstractDynamism`
#####

abstract type AbstractDynamism end

struct Dynamic <: AbstractDynamism end

struct Static <: AbstractDynamism end

dynamism(::Func, ::Any) = Dynamic()

#####
##### `mode`
#####

const FORWARD_MODE_THRESHOLDS = (general = 10, dynamism = 100)

function modal_rule(func::Func, f::Any, forward_mode_thresholds = FORWARD_MODE_THRESHOLDS)
    nwrts = wrt_count(func)
    if nwrts <= forward_mode_thresholds.general || nwrts <= target_count(func)
        return forward_rule
    elseif dynamism(func, f) && nwrts <= forward_mode_thresholds.dynamism
        return forward_rule
    end
    return reverse_rule
end
=#
