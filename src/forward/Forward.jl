module Forward

import ..Capstan
import Cassette
import DiffRules
import StaticArrays

Cassette.@context ForwardCtx

Cassette.metadatatype(::Type{<:ForwardCtx{Val{N}}}, ::Type{T}) where {N,T<:Number} = SVector{N,T}
Cassette.metadatatype(::Type{<:ForwardCtx{Int}}, ::Type{T}) where {T<:Number} = Vector{T}

include("wrt.jl")
include("primitives.jl")

end # module
