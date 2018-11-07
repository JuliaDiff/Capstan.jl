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

#=
Note that initially, this used to be:

```
struct Func{S <: Signature} <: AbstractArgument
    signature::S
end
```

While aesthetically nice (since it enables richer markup descriptions via nested
function signatures), this capability seemed to confer no actual advantage in
practice. On the contrary, it somewhat encourages over-specification in rule
definition.
=#
struct Func <: AbstractArgument end

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

#####
##### `@sig`
#####

macro sig(expr)
    signature_type_from_expr(expr)
end

const MALFORMED_SIG_ERROR_MESSAGE = "Malformed expression given to `@sig`; see `@sig` docstring for proper format."

function signature_type_from_expr(expr)
    @assert(expr.head === :call && expr.args[1] === :→ && length(expr.args) === 3, MALFORMED_SIG_ERROR_MESSAGE)
    input_types = map(parse_into_markup_type, split_infix_args(expr.args[2], :⊗))
    output_types = map(parse_into_markup_type, split_infix_args(expr.args[3], :⊗))
    return :(Signature{<:Tuple{$(input_types...)}, <:Tuple{$(output_types...)}})
end

split_infix_args(invocation::Symbol, ::Symbol) = (invocation,)

function split_infix_args(invocation::Expr, op::Symbol)
    if invocation.head === :call && invocation.args[1] === op
        return (split_infix_args(invocation.args[2], op)..., invocation.args[3])
    end
    return (invocation,)
end

function parse_into_markup_type(x)
    if x === :R
        return :(Scalar{RealDomain})
    elseif x === :C
        return :(Scalar{ComplexDomain})
    elseif x === :F
        return :(Func)
    elseif isa(x, Expr) && x.head === :vect && length(x.args) === 1
        domain = x.args[1]
        if domain === :R
            return :(Tensor{RealDomain})
        elseif domain === :C
            return :(Tensor{ComplexDomain})
        elseif domain === :F
            return :(Tensor{Func})
        end
    end
    error(string("Encountered unparseable signature element `", x, "`;",
                 MALFORMED_SIG_ERROR_MESSAGE))
end
