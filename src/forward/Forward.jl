module Forward

import ..Capstan
import Cassette
import DiffRules
import StaticArrays

Cassette.@context ForwardCtx

Cassette.metadatatype(::Type{<:ForwardCtx{Val{N}}}, ::Type{T}) where {N,T<:Real} = SVector{N,T}
Cassette.metadatatype(::Type{<:ForwardCtx{Int}}, ::Type{T}) where {T<:Real} = Vector{T}

include("api.jl")
# include("primitives.jl")

end # module
