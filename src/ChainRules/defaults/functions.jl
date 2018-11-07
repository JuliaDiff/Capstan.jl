#=
TODO: Define the required methods to cover all relevant types from:
    - StaticArrays
    - Base
    - LinearAlgebra
=#

#== `sin` ==#

function forward_rule(::@sig(R → R), ::typeof(sin), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> forward_chain(@thunk(cosx), ẋ)
end

#== `cos` ==#

function forward_rule(::@sig(R → R), ::typeof(cos), x)
    sinx, cosx = sincos(x)
    return cosx, ẋ -> forward_chain(@thunk(-sinx), ẋ)
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

function reverse_rule(::@sig(R⊗R → R), ::typeof(atan), y, x)
    h = hypot(y, x)
    return atan(y, x),
           (ȳ, x̄, z̄) -> (reverse_chain!(ȳ, @thunk((x / h) * z̄)),
                         reverse_chain!(x̄, @thunk((y / h) * z̄)))
end

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

function reverse_rule(::@sig(F⊗[R] → [R]), ::typeof(map), f, x)
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
