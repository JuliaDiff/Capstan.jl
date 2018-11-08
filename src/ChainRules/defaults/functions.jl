#=
TODO: Define...
    - ...moar rules
    - ...moar complex/mode specializations
=#

#== `sin` ==#

function forward_rule(::@sig(R → R), ::typeof(sin), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> forward_chain(@thunk(cosx), ẋ)
end

function forward_rule(::@sig(C → C), ::typeof(sin), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> (forward_chain(@thunk(cosx), ẋ), false)
end

#== `cos` ==#

function forward_rule(::@sig(R → R), ::typeof(cos), x)
    sinx, cosx = sincos(x)
    return cosx, ẋ -> forward_chain(@thunk(-sinx), ẋ)
end

function forward_rule(::@sig(C → C), ::typeof(cos), x)
    sinx, cosx = sincos(x)
    return cosx, ẋ -> (forward_chain(@thunk(-sinx), ẋ), false)
end

#== `sincos` ==#

function forward_rule(::@sig(R → R⊗R), ::typeof(sincos), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> forward_chain(cosx, ẋ),
           cosx, ẋ -> forward_chain(@thunk(-sinx), ẋ)
end

function reverse_rule(::@sig(R → R⊗R), ::typeof(sincos), x)
    sinx, cosx = sincos(x)
    return sinx, (x̄, z̄₁) -> reverse_chain!(x̄, @thunk(cosx * z̄₁))
           cosx, (x̄, z̄₂) -> reverse_chain!(x̄, @thunk(-sinx * z̄₂))
end

#== `atan` ==#

function forward_rule(::@sig(R⊗R → R), ::typeof(atan), y, x)
    h = hypot(y, x)
    return atan(y, x),
           (ẏ, ẋ) -> forward_chain(@thunk(x / h), ẏ, @thunk(y / h), ẋ)
end

#== `conj` ==#

function forward_rule(::@sig(C → C), ::typeof(conj), x)
    return conj(x), ẋ -> (false, true)
end

#== `log` ==#

# TODO

#== `sum` ==#

function reverse_rule(::@sig([R] → R), ::typeof(sum), x)
    return sum(x),
           (x̄, z̄) -> reverse_chain!(x̄, @thunk(z̄))
end

#== `+` ==#

function reverse_rule(::@sig([R]⊗[R] → R), ::typeof(+), x, y)
    return x + y,
           (x̄, ȳ, z̄) -> (reverse_chain!(x̄, @thunk(z̄)),
                         reverse_chain!(ȳ, @thunk(z̄)))
end

#== `*` ==#

function reverse_rule(::@sig([R]⊗[R] → R), ::typeof(*), x, y)
    return x * y,
           (x̄, ȳ, z̄) -> (reverse_chain!(x̄, @thunk(z̄ * y')),
                         reverse_chain!(ȳ, @thunk(x' * z̄)))
end

#== `map` ==#


function reverse_rule(::@sig(_⊗[R] → [R]), ::typeof(map), f, x)
    f_sig = Signature((Scalar(RealDomain()),), (Scalar(RealDomain()),))
    f_rule = x -> begin
        y, d = forward_rule(f_sig, f, x)
        y, d(one(x))
    end
    # TODO: This should be doable without the extra temporaries or preallocation
    # utilized here, but AFAICT such an approach is hard to write without
    # relying on inference hacks unless we have something akin to
    # https://github.com/JuliaLang/julia/issues/22129
    applied_f_rule = map(f_rule, x)
    values = map(first, applied_f_rule)
    derivs = map(last, applied_f_rule)
    return values, (x̄, z̄) -> reverse_chain!(x̄, @thunk(broadcasted(*, derivs, z̄)))
end

function reverse_rule(::@sig(_⊗[C] → [C]), ::typeof(map), f, x)
    f_sig = Signature((Scalar(ComplexDomain()),), (Scalar(ComplexDomain()),))
    f_rule = x -> begin
        y, d = forward_rule(f_sig, f, x)
        y, d(one(x) + im) # TODO: Is this even the right seeding at all?
    end
    # TODO: Same allocation/temporaries issue as the real-valued version above.
    # Additionally, it's unclear whether this is even the right way to do
    # Wirtinger-style reverse propagation...
    applied_f_rule = map(f_rule, x)
    values = map(first, applied_f_rule)
    primal_derivs = map(((x, (y, y⁺)),) -> y, applied_f_rule)
    conjugate_derivs = map(((x, (y, y⁺)),) -> y⁺, applied_f_rule)
    return values,
            # TODO how to write the reverse-mode Wirtinger derivative propagation?
end
