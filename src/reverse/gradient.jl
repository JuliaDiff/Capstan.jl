############
# Gradient #
############

struct Gradient{C<:RDiffCtx,F,S}
    context::C
    func::F
    tape::Tape
    variables::VariableCache{S}
    wrt::Vector{UInt}
    isdynamic::Bool
end

Gradient(f, ::Type{S} = Any, isdynamic = true) where {S} = Gradient(RDiffCtx(f), f, Tape(), VariableCache{S}(), Vector{UInt}(), isdynamic)

function (g::Gradient)(input...)
    output = forwardpass!(g, input...)
    reversepass!(g, output)
    return unboxall(g.context, output)
end

function forwardpass!(g::Gradient, input...)
    # TODO: perform static optimizations and reuse tape if `!(d.isdynamic)`
    empty!(g.tape)
    empty!(g.variables, g.wrt)
    return overdub(g.context, g.func, g)(input...)
end

function reversepass!(g::Gradient, output)
    if isboxed(g.context, output)
        index = meta(g.context, output)
        if !(is_sentinel_scalar_index(index))
            seed!(g.variables, index)
            reversepass!(g.tape)
        end
    end
    return nothing
end

#############
# `wrt` API #
#############

function wrt!(g::Gradient, x)
    addvariable!(g.variables.tensors, x)
    push!(g.wrt, object_id(x))
    return x
end

iswrt(g::Gradient, x) = in(object_id(x), g.wrt)

function wrt(g::Gradient, x)
    @assert iswrt(g, x)
    return deriv(getvariable(g.variables.tensors, x))
end

function rmwrt!(g::Gradient, x)
    x_id = object_id(x)
    for (i, id) in enumerate(g.wrt)
        if id == x_id
            delete!(g.wrt, i)
            delete!(g.variables.tensors, x)
            break
        end
    end
    return g
end

#############
# recording #
#############

function hasvariable(g::Gradient, x)
    key = isboxed(g.context, x) ? meta(g.context, x) : x
    return hasvariable(g.variables, key)
end

function track!(g::Gradient, values, isdependent::Bool)
    return tuplemap(values) do x
        if Capstan.isscalar(x)
            index = isdependent ? addvariable!(g.variables, x) : sentinel_scalar_index(x)
            return Box(g.context, x, index)
        else
            Capstan.istensor(x) && isdependent && addvariable!(g.variables, x)
            return x
        end
    end
end

# this is type unstable, but that shouldn't matter
function variablize(g::Gradient, args)
    return tuplemap(args) do x
        key = isboxed(g.context, x) ? meta(g.context, x) : x
        if hasvariable(g.variables, key)
            return getvariable(g.variables, key)
        else
            return x
        end
    end
end

function record!(g::Gradient, f, input, output)
    isdependent = any(hasvariable(g, x) for x in input)
    tracked = track!(g, output, isdependent)
    if isdependent
        push!(g.tape, Instruction(f, variablize(g, input), variablize(g, tracked)))
    end
    return tracked
end
