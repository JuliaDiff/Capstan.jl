##############
# chunk size #
##############

const DEFAULT_CHUNK_THRESHOLD = 10

# constrained to `pickchunksize(len, threshold) <= threshold`, minimize in order of priority:
#   1. the number of chunks that need to be computed
#   2. the number of "left over" perturbations in the final chunk
function _pickchunksize(len::Int, threshold::Int = DEFAULT_CHUNK_THRESHOLD)
    if len <= threshold
        return len
    else
        nchunks = round(Int, len / threshold, RoundUp)
        return round(Int, len / nchunks, RoundUp)
    end
end

# `init` can be an `Int`, `Val(::Int)` #, `nothing` or `Val(nothing)`
function pickchunksize(init, len::Int, threshold::Int = DEFAULT_CHUNK_THRESHOLD)
    if isa(init, Nothing) || isa(init, Val{nothing})
        c = pickchunksize(len, threshold)
        return isa(init, Val{nothing}) ? Val(c) : c
    else
        @assert isa(init, Int) || isa(init, Val)
        return init
    end
end

#########
# `Wrt` #
#########

typealias AllowedWrtTypes = Union{Real,Complex,Array,StaticArray}

struct Wrt{V<:AllowedWrtTypes,S<:AllowedWrtTypes}
    value::V
    seed::S
    Wrt(value::V, seed::S = defaultseed(value)) where {V,S} = new{V,S}(value, seed)
end

defaultseed(x::Real) = one(x)
defaultseed(x::Complex) = Complex(one(x), one(x))
defaultseed(x::AbstractArray) = defaultseed.(x)
defaultseed(x::AbstractArray{T}) where {T<:Real} = one(T)
defaultseed(x::AbstractArray{T}) where {T<:Complex} = Complex(one(T), one(T))

##########
# tagwrt #
##########

unbound_getindex(x::AbstractArray, i) = x[i]
unbound_getindex(x::Number, i) = x

function tagwrt(context::ForwardCtx{Val{N}}, wrt::Wrt{<:Real}, position::Union{Int,Nothing}) where {N}
    derivs = zeros(SVector{N,typeof(wrt.seed)})
    derivs = isa(position, Int) ? setindex(derivs, wrt.seed, position) : derivs
    return Cassette.tag(wrt.value, context, derivs)
end

function tagwrt(context::ForwardCtx{Int}, wrt::Wrt{<:Real}, position::Union{Int,Nothing})
    derivs = fill(zero(typeof(wrt.seed)), context.metadata)
    isa(position, Int) && (derivs[position] = wrt.seed)
    return Cassette.tag(wrt.value, context, derivs)
end

function tagwrt(context::ForwardCtx, wrt::Wrt{V,S}, position::Tuple) where {V<:Complex,S<:Complex}
    realwrt = tagwrt(context, Wrt(real(wrt.value), real(wrt.seed)), position[1])
    imagwrt = tagwrt(context, Wrt(imag(wrt.value), imag(wrt.seed)), position[2])
    return Cassette.tagged_new(context, promote_type(V, S), realwrt, imagwrt)
end

function tagwrt(context::ForwardCtx, wrt::Wrt{<:Array}, positions)
    tagged = Cassette.tag(wrt.value, context)
    position_counter = first(position_bounds)
    for i in 1:length(wrt.value)
        wrt_element = Wrt(wrt.value[i], unbound_getindex(wrt.seed, i))
        if in(position_counter, position_bounds)
            if isa(wrt_element.value, Complex)
                current_position = position_counter
            else
        else
            current_position = nothing
        end
        tagged_element = tagwrt(context, wrt, position)
        Cassette.tagged_arrayset(context, false, tagged, tagged_element, i)
    end
    return tagged
end

# function tagwrt(context::ForwardCtx, wrt::Wrt{<:Array}, position::UnitRange{Int})
#     # how to handle position seeding?
#     # kernel = Cassette.Primitive((v, s, p) -> tagwrt(context, Wrt(v, s), p), context) do (v, s, p)
#     # return Cassette.overdub(context, broadcast, kernel, wrt.value, wrt.seed, position)
# end

function setupwrts(f, wrts::Wrt...; chunksize = Val(nothing), threshold = DEFAULT_CHUNK_THRESHOLD)
    chunksize = pickchunksize(chunksize, sum(length(wrt.value) for wrt in wrts), threshold)
    positions = assignchunks(wrts, chunksize)
    context = Cassette.withtagfor(ForwardCtx(metadata = chunksize), f)
    return context, tagwrt.(context, wrts, positions)
end

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
