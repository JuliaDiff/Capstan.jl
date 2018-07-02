###############
# `propagate` #
###############

propagate(dfdx, dx) = dfdx .* dx
propagate(dfdx, dx, dfdy, dy) = dfdx .* dx .+ dfdy .* dy
propagate(dfdx, dx, dfdy, dy, dfdz, dz) = dfdx .* dx .+ dfdy .* dy .+ dfdz .* dz
propagate(dfdx, dx, dfdy, dy, dfdz, dz, rest...) = propagate(dfdx, dx, dfdy, dy, dfdz, dz) .+ propagate(rest...)

################
# `@primitive` #
################

function primitive_definitions_from_diffrule(M, f, arity)
    xs = [Symbol(:x, i) for i in 1:arity]
    vxs = [Symbol(:vx, i) for i in 1:arity]
    dxs = [Symbol(:dx, i) for i in 1:arity]
    dfdxs = DiffRules.diffrule(M, f, vxs...)
    if arity == 1
        dfdxs = (dfdxs,)
    end
    method_defs = Expr(:block)
    for active_indices in argument_permutations(arity)
        unpacked_args = Expr[]
        propagate_call = Expr(:call, :propagate)
        for i in active_indices
            vx_expr = :($Cassette.untag($(xs[i]), __context__))
            dx_expr = :($Cassette.meta($(xs[i]), __context__))
            push!(unpacked_args, Expr(:(=), Expr(:tuple, vxs[i], dxs[i]), Expr(:tuple, vx_expr, dx_expr)))
            push!(propagate_call.args, dfdxs[i])
            push!(propagate_call.args, dxs[i])
        end
        method_args = Any[]
        for i in 1:arity
            if i in active_indices
                push!(method_args, Expr(:(::), xs[i], :($Cassette.Tagged{T,<:Real})))
            else
                push!(method_args, xs[i])
            end
        end
        push!(method_defs.args, quote
            $Cassette.@primitive function (::typeof($M.$f))($(method_args...)) where {T,__CONTEXT__<:ForwardCtx{<:Any,T}}
                $(unpacked_args...)
                return $Cassette.tag($M.$f($(vxs...)), __context__, $(propagate_call))
            end
        end)
    end
    return method_defs
end

argument_permutations(arity) = [findall(x -> x == '1', string(i, base=2, pad=arity)) for i in 1:(2^arity - 1)]

macro primitive(expr)
    return esc(quote
        key = $DiffRules.@define_diffrule $expr
        Core.eval($(__module__), $Forward.primitive_definitions_from_diffrule(key...))
    end)
end

################################
# default primitive generation #
################################

for (M, f, arity) in DiffRules.diffrules()
    M == :Base || continue
    @eval $(primitive_definitions_from_diffrule(M, f, arity))
end
