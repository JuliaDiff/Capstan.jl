#####
##### `description`
#####

description(args::Tuple) = map(description, args)

#####
##### `AbstractLayout`
#####

abstract type AbstractLayout end

struct Layout{C<:Union{Int,Val},S} <: AbstractLayout
    count::C
    shape::S
    ismutable::Bool
end

element_count(layout::Layout{Int}) = layout.count
element_count(::Layout{Val{count}}) where {count} = count

#####
##### `AbstractDomain`
#####

abstract type AbstractDomain end

struct RealDomain <: AbstractDomain end

struct ComplexDomain <: AbstractDomain end

#####
##### `AbstractArgument`
#####

abstract type AbstractArgument end

#== `Signature` ==#

struct Signature{I <: Tuple{Vararg{AbstractArgument}},
                 O <: Tuple{Vararg{AbstractArgument}}}
    input::I
    output::O
end

input_count(sig::Signature) = sum(element_count, sig.input)

output_count(sig::Signature) = sum(element_count, sig.output)

#== `Func` ==#

struct Func{S <: Signature} <: AbstractArgument
    signature::S
end

element_count(::Func) = 0

#== `AbstractVariable` ==#

abstract type AbstractVariable <: AbstractArgument end

struct Scalar{D <: AbstractDomain} <: AbstractVariable
    domain::D
end

struct Tensor{D <: AbstractDomain, L <: AbstractLayout} <: AbstractVariable
    domain::D
    layout::L
end

element_count(::Scalar) = 1
element_count(t::Tensor) = element_count(t.layout)
