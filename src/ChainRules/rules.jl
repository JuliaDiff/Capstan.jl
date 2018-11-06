#####
##### rules
#####

forward_rule(::Signature, ::Any, ::Vararg{Any}) = nothing

reverse_rule(::Signature, ::Any, ::Vararg{Any}) = nothing

#####
##### `Thunk`
#####

macro _(body)
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



#####
##### TODO
#####

#=
- forward_chain/reverse_chain! implementations
- bring back properties as needed (see git history), e.g.:
    - `AbstractMode`
    - `AbstractLinearity`
    - `AbstractDynamism`
=#
