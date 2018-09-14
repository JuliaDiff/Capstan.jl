#== `sin` ==#

function forward_rule(::@sigtype(R → R), ::typeof(sin), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> @forward_chain(cosx, ẋ)
end

#== `cos` ==#

function forward_rule(::@sigtype(R → R), ::typeof(cos), x)
    sinx, cosx = sincos(x)
    return cosx, ẋ -> @forward_chain(-sinx, ẋ)
end

#== `sincos` ==#

function forward_rule(::@sigtype(R → R⊗R), ::typeof(sincos), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> @forward_chain(cosx, ẋ),
           cosx, ẋ -> @forward_chain(-sinx, ẋ)
end

#== `atan` ==#

function forward_rule(::@sigtype(R⊗R → R), ::typeof(atan), y, x)
    h = hypot(y, x)
    return atan(y, x),
           (ẏ, ẋ) -> @forward_chain(x / h, ẏ, y / h, ẋ)
end

#== `sum` ==#

function reverse_rule(::@sigtype([R] → R), ::typeof(sum), x)
    return sum(x),
           (x̄, z̄) -> @reverse_chain!(x̄, z̄)
end

#== `+` ==#

function reverse_rule(::@sigtype([R]⊗[R] → R), ::typeof(+), x, y)
    return x + y,
           (x̄, ȳ, z̄) -> (@reverse_chain!(x̄, z̄); @reverse_chain!(ȳ, z̄))
end

#== `*` ==#

function reverse_rule(::@sigtype([R]⊗[R] → R), ::typeof(*), x, y)
    return x * y,
           (x̄, ȳ, z̄) -> (@reverse_chain!(x̄, z̄ * y'); @reverse_chain!(ȳ, x' * z̄))
end

#== `map` ==#

function reverse_rule(::@sigtype(F{R → R}⊗[R] → [R]), ::typeof(map), f, x)
    f_sig = @sig(R → R)
    f_rule = x -> begin
        y, d = forward_rule(f_sig, f, x)
        y, d(one(x))
    end
    # TODO: this could be done in a way which doesn't require extra
    # temporaries (or preallocation, which is hard to do without inference
    # hacks) if we had just had something akin to
    # https://github.com/JuliaLang/julia/issues/22129
    applied_f_rule = map(f_rule, x)
    values = map(first, applied_f_rule)
    derivs = map(last, applied_f_rule)
    return values, (x̄, z̄) -> @reverse_chain!(x̄, derivs .* z̄)
end
