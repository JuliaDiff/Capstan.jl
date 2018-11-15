#####
##### fallback rules
#####

# TODO: Should the default be to whitelist known holomorphic functions, or to
# blacklist known non-holomorphic functions? This implements the latter.
function forward_rule(signature::@sig(C → C), f, x)
    real_signature = Signature(RealScalar(), RealScalar())
    fx, df = forward_rule(real_signature, f, x)
    return fx, ẋ -> (df(ẋ), false)
end

function reverse_rule(s::@sig(R → R), f, x)
    fx, df = forward_rule(s, f, x)
    return fx, (x̄, z̄) -> reverse_chain!(x̄, @thunk(df(z̄)))
end

#####
##### `forward_rule`
#####

function forward_rule(::@sig(R → R), ::typeof(sin), x)
    return sin(x), ẋ -> forward_chain(@thunk(cos(x), ẋ))
end

function forward_rule(::@sig(R → R), ::typeof(cos), x)
    return cos(x), ẋ -> forward_chain(@thunk(-sin(x)), ẋ)
end

function forward_rule(::@sig(R → R⊗R), ::typeof(sincos), x)
    sinx, cosx = sincos(x)
    return sinx, ẋ -> forward_chain(@thunk(cosx), ẋ),
           cosx, ẋ -> forward_chain(@thunk(-sinx), ẋ)
end

function forward_rule(::@sig(R⊗R → R), ::typeof(atan), y, x)
    h = hypot(y, x)
    return atan(y, x),
           (ẏ, ẋ) -> forward_chain(@thunk(x / h), ẏ, @thunk(y / h), ẋ)
end

function forward_rule(::@sig(R → R), ::typeof(log), x)
    return log(x), ẋ -> forward_chain(@thunk(inv(x)), ẋ)
end

forward_rule(::@sig(C → C), ::typeof(conj), x) = conj(x), ẋ -> (false, true)

#####
##### `reverse_rule`
#####

function reverse_rule(::@sig([R] → R), ::typeof(sum), x)
    return sum(x),
           (x̄, z̄) -> reverse_chain!(x̄, @thunk(z̄))
end

function reverse_rule(::@sig([R]⊗[R] → R), ::typeof(+), x, y)
    return x + y,
           (x̄, ȳ, z̄) -> (reverse_chain!(x̄, @thunk(z̄)),
                         reverse_chain!(ȳ, @thunk(z̄)))
end

function reverse_rule(::@sig([R]⊗[R] → R), ::typeof(*), x, y)
    return x * y,
           (x̄, ȳ, z̄) -> (reverse_chain!(x̄, @thunk(z̄ * y')),
                         reverse_chain!(ȳ, @thunk(x' * z̄)))
end

function reverse_rule(::@sig(_⊗[R] → [R]), ::typeof(map), f, x)
    f_sig = Signature(RealScalar(), RealScalar())
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
    return values, (x̄, z̄) -> reverse_chain!(x̄, @thunk(broadcasted(*, z̄, derivs)))
end

# function reverse_rule(::@sig(_⊗[C] → [C]), ::typeof(map), f, x)
#     f_sig = Signature((ComplexScalar(),), (Scalar(ComplexDomain()),))
#     f_rule = x -> begin
#         y, d = forward_rule(f_sig, f, x)
#         y, d(one(x) + im) # TODO: Is this even the right seeding at all?
#     end
#     # TODO: Same allocation/temporaries issue as the real-valued version above.
#     # Additionally, it's unclear whether this is even the right way to do
#     # Wirtinger-style reverse propagation...
#     applied_f_rule = map(f_rule, x)
#     values = map(first, applied_f_rule)
#     primal_derivs = map(((x, (y, y⁺)),) -> y, applied_f_rule)
#     conjugate_derivs = map(((x, (y, y⁺)),) -> y⁺, applied_f_rule)
#     return values,
#             # TODO how to write the reverse-mode Wirtinger derivative propagation?
# end
