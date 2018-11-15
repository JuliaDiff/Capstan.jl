#=
TODO: Define the required methods to cover all relevant types from:
    - StaticArrays
    - Base
    - LinearAlgebra
=#

#####
##### `description`
#####

description(args::Tuple) = map(description, args)
description(::Any) = Ignore()
description(::Real) = Scalar(RealDomain())
description(::Complex) = Scalar(ComplexDomain())
description(x::AbstractArray{<:Real}) = Tensor(RealDomain(), layout(x))
description(x::AbstractArray{<:Complex}) = Tensor(ComplexDomain(), layout(x))

#####
##### `layout`
#####

layout(x::Array) = Layout(length(x), size(x), true)

#####
##### `should_materialize_into`
#####

should_materialize_into(::Array) = true
