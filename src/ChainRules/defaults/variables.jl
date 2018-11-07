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
description(::Function) = Func()
description(::Real) = Scalar(RealDomain())
description(::Complex) = Scalar(ComplexDomain())
description(x::AbstractArray{<:Real}) = Tensor(RealDomain(), layout(x))
description(x::AbstractArray{<:Complex}) = Tensor(ComplexDomain(), layout(x))

#####
##### `layout`
#####

layout(x::Array) = Layout(length(x), size(x), true)

#####
##### adjoint interface
#####

value(x̄) = x̄

should_increment(x̄) = true

should_materialize_into(x̄::Number) = false
should_materialize_into(x̄::Array) = true
