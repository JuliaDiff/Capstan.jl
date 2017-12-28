module Capstan

import Cassette

isscalar(x) = isscalar(typeof(x))
isscalar(::DataType) = false
isscalar(::Type{<:Number}) = true
isscalar(::Type{<:Cassette.Box{<:Any,U}}) where {U} = isscalar(U)

istensor(x) = istensor(typeof(x))
istensor(::DataType) = false
istensor(::Type{<:AbstractArray}) = true
istensor(::Type{<:Cassette.Box{<:Any,U}}) where {U} = istensor(U)

include("forward/Forward.jl")
include("reverse/Reverse.jl")

end # module
