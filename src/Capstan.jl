module Capstan

import Cassette

isscalar(x) = isscalar(typeof(x))
isscalar(::DataType) = false
isscalar(::Type{<:Number}) = true

istensor(x) = istensor(typeof(x))
istensor(::DataType) = false
istensor(::Type{<:AbstractArray}) = true

include("forward/Forward.jl")
# include("reverse/Reverse.jl")

end # module
