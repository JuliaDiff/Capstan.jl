#####
##### rules
#####
#=
There's an idea at play here that's not made explicit in these fallbacks. In
some weird ideal sense, the fallback for e.g. `forward_rule` should actually be
"get the derivative via forward-mode AD". This is necessary to enable mixed-mode
rules, where e.g. `forward_rule` is used within a `reverse_rule` definition. For
example, `map`ped/`broadcast`ed functions may not themselves be forward-mode
*primitives*, but are forward-mode *differentiable*.

The problem is that ChainRules is (and should be) decoupled from any specific
AD implementation. How, then, do we know which AD to fall back to when there
isn't a primitive defined?

I guess we could pass around some callback or something through to every rule to
tell the fallback rule which AD to use, but...wait! That's exactly what Cassette
allows you to do: pass around a context! Better yet, we don't have to add any of
that machinery to ChainRules itself - downstream AD tools can use Cassette to
inject their contexts post-hoc.

Thus, that's the interface for downstream AD tools to support mixed-mode chain
rules; just overload these `forward_rule`/`reverse_rule` fallbacks w.r.t. their
own contexts via Cassette.
=#

forward_rule(::Signature, ::Any, ::Vararg{Any}) = nothing

reverse_rule(::Signature, ::Any, ::Vararg{Any}) = nothing

#####
##### `Thunk`
#####

macro thunk(body)
    return :(Thunk(() -> $(esc(body))))
end

struct Thunk{F}
    f::F
end

@inline (thunk::Thunk{F})() where {F} = (thunk.f)()

#####
##### `forward_chain`
#####

forward_chain(args...) = materialize(_forward_chain(args...))

@inline _forward_chain(∂x::Thunk, ẋ::Nothing) = false
@inline _forward_chain(∂x::Thunk, ẋ) = broadcasted(*, ∂x(), ẋ)
_forward_chain(∂x::Thunk, ẋ, args...) = broadcasted(+, _forward_chain(∂x, ẋ), _forward_chain(args...))

#####
##### `reverse_chain`
#####

@inline reverse_chain!(x̄::Nothing, ∂x::Thunk) = false

@inline function reverse_chain!(x̄, ∂x::Thunk)
    thunk = ∂x()
    casted = should_increment(x̄) ? broadcasted(+, value(x̄), thunk) : thunk
    if should_materialize_into(x̄)
        return materialize!(value(x̄), casted)
    else
        return materialize(casted)
    end
end

#####
##### TODO
#####

#=
- bring back properties as needed (see git history), e.g.:
    - `AbstractMode`
    - `AbstractLinearity`
    - `AbstractDynamism`
=#
