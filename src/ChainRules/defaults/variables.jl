description(x::Real) = Scalar(RealDomain())
description(x::Complex) = Scalar(ComplexDomain())
description(x::AbstractArray{<:Real}) = Tensor(RealDomain(), layout(x))
description(x::AbstractArray{<:Complex}) = Tensor(ComplexDomain(), layout(x))

layout(x::Array) = Layout(length(x), size(x), true)

#=
TODO:
    - StaticArrays
    - Base
    - LinearAlgebra
=#
