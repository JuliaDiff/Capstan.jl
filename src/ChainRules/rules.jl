struct NoRule end

forward_rule(::Signature, ::Any, ::Vararg{Any}) = NoRule()

reverse_rule(::Signature, ::Any, ::Vararg{Any}) = NoRule()

#=
TODO:
    - @forward_chain/@reverse_chain! implementations
    - bring back properties as needed (see git history), e.g.:
        - `AbstractMode`
        - `AbstractLinearity`
        - `AbstractDynamism`
=#
