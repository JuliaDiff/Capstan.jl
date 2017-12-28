macro primitive(signature)
    @assert isa(signature, Expr)
    f, g, output = gensym("f"), gensym("g"), gensym("output")
    if signature.head == :call
        call = signature
    elseif signature.head == :where
        call = signature.args[1]
    else
        error("invalid input to Capstan.Reverse.@primitive: ", signature)
    end
    call.args[1] = :($f::typeof($(call.args[1])))
    args = call.args[2:end]
    # we use `$signature = begin...end` instead of `function $signature ... end`
    # here because of https://github.com/JuliaLang/julia/issues/25080
    return esc(quote
        $Cassette.@primitive $Reverse.RDiffCtx $g::$Reverse.Gradient $signature = begin
            $output = $Cassette.mapcall(x -> $Cassette.unbox($g.context, x), $f, $(args...))
            return $Reverse.record!($g, $f, ($(args...),), $output)
        end
    end)
end

@primitive Base.sum(x)
back!(::typeof(sum), x, y) = @propagate!(x, deriv(y))

@primitive Base.:+(x, y)
function back!(::typeof(+), x, y, z)
    @propagate!(x, deriv(z) .* value(y))
    @propagate!(y, deriv(z) .* value(x))
end

@primitive Base.:*(x, y)
function back!(::typeof(*), x, y, z)
    @propagate!(x, A_mul_Bc(deriv(z), value(y)))
    @propagate!(y, Ac_mul_B(value(x), deriv(z)))
end
