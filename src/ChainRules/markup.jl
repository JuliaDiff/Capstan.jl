#####
##### `AbstractLayout`
#####

abstract type AbstractLayout end

struct CPUDevice end

struct Layout{L, S, D} <: AbstractLayout
    length::L
    size::S
    device::D
    ismutable::Bool
end

Base.length(layout::Layout) = layout.length

Base.size(layout::Layout) = layout.size

device(layout::Layout) = layout.device

ismutable(layout::Layout) = layout.ismutable

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

Signature(input, output) = Signature(tuplify(x), tuplify(y))

tuplify(x) = tuple(x)
tuplify(x::Tuple) = x

input_count(sig::Signature) = sum(element_count, sig.input)

output_count(sig::Signature) = sum(element_count, sig.output)

#== `Ignore` ==#

struct Ignore <: AbstractArgument end

element_count(::Ignore) = 0

#== `AbstractVariable` ==#

abstract type AbstractVariable <: AbstractArgument end

struct Scalar{D <: AbstractDomain} <: AbstractVariable
    domain::D
end

const RealScalar = Scalar{RealDomain}

RealScalar() = Scalar(RealDomain())

const ComplexScalar = Scalar{ComplexDomain}

ComplexScalar() = Scalar(ComplexDomain())

struct Tensor{D <: AbstractDomain, L <: AbstractLayout} <: AbstractVariable
    domain::D
    layout::L
end

const RealTensor = Tensor{RealDomain}

RealTensor(layout) = Tensor(RealDomain(), layout)

const ComplexTensor = Tensor{ComplexDomain}

ComplexTensor(layout) = Tensor(ComplexDomain(), layout)

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
    elseif x === :_
        return :(Ignore)
    elseif isa(x, Expr) && length(x.args) === 1
        if x.head === :vect
            domain = x.args[1]
            if domain === :R
                return :(Tensor{RealDomain})
            elseif domain === :C
                return :(Tensor{ComplexDomain})
            end
        elseif x.head === :braces
            vararg_type = parse_into_markup_type(x.args[1])
            return :(Vararg{$vararg_type})
        end
    end
    error(string("Encountered unparseable signature element `", x, "`. ",
                 MALFORMED_SIG_ERROR_MESSAGE))
end
