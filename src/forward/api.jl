#########
# `Wrt` #
#########

struct Wrt{V,S}
    value::V
    seed::S
    Wrt(value::V, seed::S = defaultseed(value)) where {V,S} = new{V,S}(value, seed)
end

defaultseed(x::Real) = one(x)
defaultseed(x::Complex) = Complex(one(x), one(x))
defaultseed(x::AbstractArray) = defaultseed.(x)
defaultseed(x::AbstractArray{T}) where {T<:Real} = one(T)
defaultseed(x::AbstractArray{T}) where {T<:Complex} = Complex(one(T), one(T))

function tagwrt(context::ForwardCtx{Val{N}}, wrt::Wrt{<:Real}, position::Int) where {N}
    derivs = setindex(zeros(SVector{N,typeof(wrt.seed)}), wrt.seed, position)
    return Cassette.tag(wrt.value, context, derivs)
end

function tagwrt(context::ForwardCtx{Int}, wrt::Wrt{<:Real}, position::Int) where {N}
    derivs = fill(zero(typeof(wrt.seed)), context.metadata)
    derivs[position] = wrt.seed
    return Cassette.tag(wrt.value, context, derivs)
end

function tagwrt(context::ForwardCtx, wrt::Wrt{<:Complex}, position::Tuple{Int,Int})
    realwrt = tagwrt(context, Wrt(real(wrt.value), real(wrt.seed)), position[1])
    imagwrt = tagwrt(context, Wrt(imag(wrt.value), imag(wrt.seed)), position[2])
    return overdub(context, Complex, realwrt, imagwrt)
end

function tagwrt(context::ForwardCtx, wrt::Wrt{<:AbstractArray}, position::UnitRange{Int})
    # how to handle position seeding?
    kernel = Cassette.Primitive((v, s, p) -> tagwrt(context, Wrt(v, s), p), context)
    return Cassette.overdub(context, broadcast, kernel, wrt.value, wrt.seed, position)
end

# ##################
# # `DualArgument` #
# ##################
#
# const DEFAULT_CHUNK_THRESHOLD = 10
#
# # Constrained to `N <= threshold`, minimize (in order of priority):
# #   1. the number of chunks that need to be computed
# #   2. the number of "left over" perturbations in the final chunk
# function pickchunksize(inputlength::Int, threshold::Int = DEFAULT_CHUNK_THRESHOLD)
#     if inputlength <= threshold
#         return inputlength
#     else
#         nchunks = round(Int, inputlength / threshold, RoundUp)
#         return round(Int, inputlength / nchunks, RoundUp)
#     end
# end
#
# # `chunksize` can take an `Int`, `Val(::Int)`, `nothing` or `Val(nothing)`
# function tagwrts(f, wrts::Wrt...; chunksize = Val(nothing), threshold = DEFAULT_CHUNK_THRESHOLD)
#     if isa(chunksize, Nothing) || isa(chunksize, Val{nothing})
#         n = pickchunksize(sum(length(w.value) for w in wrts), threshold)
#         chunksize = isa(chunksize, Val{nothing}) ? Val(n) : n
#     end
#     ctx = Cassette.withtagfor(ForwardCtx(metadata = chunksize), f)
#     return tagwrt(...)
# end

# TangentBundle(chunksize::Int, value::Real, deriv::Real) =
# TangentBundle(chunksize::Val{n},



# struct TangentBuffers{N,I<:Tuple}
#     chunksize::ChunkSize{N}
#     wrtindices::I
#     tangents::T
# end
#
# function initbuffer(::ChunkSize{N}, totalsize::Int, value::Real, )
#
# end
#
#
# function TangentBuffers{N}(wrts::Wrt{<:Real}...)
#
# end
#
#
# gradient((x, y) -> sum(hypot.(x, y)), Wrt(rand(10), rand(10)), rand(10))
