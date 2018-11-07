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
##### propagation predicates
#####

should_increment(x̄) = true

should_materialize_into(x̄) = false
should_materialize_into(x̄::AbstractArray) = true

#=
TODO:
    - StaticArrays
    - Base
    - LinearAlgebra
=#
