####################
# AbstractVariable #
####################

abstract type AbstractVariable end

macro propagate!(x, Δ)
    return esc(quote
        (typeof($x) <: $AbstractVariable) && $incrderiv!($x, $Δ)
    end)
end

value(x) = x

###########
# Scalars #
###########

#=== ScalarIndex ===#

struct ScalarIndex{T}
    index::Int
end

sentinel_scalar_index(x::T) where {T} = ScalarIndex{T}(0)

is_sentinel_scalar_index(x) = isa(x, ScalarIndex) && x.index === 0

#=== ScalarCache ===#

struct ScalarCache{S}
    values::Vector{S}
    derivs::Vector{S}
    ScalarCache{S}() where {S} = new{S}(Vector{S}(), Vector{S}())
end

ScalarCache() = ScalarCache{Any}()

hasvariable(cache::ScalarCache, i::ScalarIndex) = 1 <= i.index <= length(cache)

getvariable(cache::ScalarCache, i::ScalarIndex) = ScalarVariable(i, cache)

function addvariable!(cache::ScalarCache, x::T) where {T}
    @assert Capstan.isscalar(x)
    push!(cache.values, x)
    push!(cache.derivs, zero(x))
    return ScalarIndex{T}(length(cache))
end

Base.empty!(cache::ScalarCache) = (Base.empty!(cache.values); Base.empty!(cache.derivs); cache)

Base.length(cache::ScalarCache) = length(cache.values) # === length(cache.derivs)

#=== ScalarVariable ===#

struct ScalarVariable{T,S} <: AbstractVariable
    index::ScalarIndex{T}
    cache::ScalarCache{S}
end

value(x::ScalarVariable{T}) where {T} = (x.cache.values[x.index.index])::T

deriv(x::ScalarVariable{T}) where {T} = (x.cache.derivs[x.index.index])::T

incrderiv!(x::ScalarVariable, y) = (x.cache.derivs[x.index.index]::T += y; nothing)

###########
# Tensors #
###########

#=== TensorCache ===#

struct TensorCache
    derivs::ObjectIdDict
    TensorCache() = new(ObjectIdDict())
end

hasvariable(cache::TensorCache, x) = haskey(cache.derivs, x)

getvariable(cache::TensorCache, x) = TensorVariable(x, cache.derivs[x]::typeof(x))

function addvariable!(cache::TensorCache, x)
    @assert Capstan.istensor(x)
    cache.derivs[x] = fill!(similar(x), zero(eltype(x)))
    return x
end

Base.empty!(cache::TensorCache) = (empty!(cache.derivs); cache)

function Base.empty!(cache::TensorCache, keep::Vector{UInt})
    filter!(kv -> in(object_id(kv.first), keep), cache.derivs)
    return cache
end

Base.delete!(cache::TensorCache, x) = (delete!(cache.derivs, x); cache)

Base.length(cache::TensorCache) = length(cache.derivs)

#=== TensorVariable ===#

struct TensorVariable{T} <: AbstractVariable
    value::T
    deriv::T
end

value(x::TensorVariable) = x.value

deriv(x::TensorVariable) = x.deriv

incrderiv!(x::TensorVariable, y) = (x.deriv .+= y; nothing)

#################
# VariableCache #
#################

struct VariableCache{S}
    scalars::ScalarCache{S}
    tensors::TensorCache
    VariableCache{S}() where {S} = new{S}(ScalarCache{S}(), TensorCache())
end

seed!(cache::VariableCache, i::ScalarIndex{T}) where {T} = (cache.scalars.derivs[i.index]::T = one(T); nothing)

hasvariable(cache::VariableCache, i::ScalarIndex) = hasvariable(cache.scalars, i)
hasvariable(cache::VariableCache, x) = hasvariable(cache.tensors, x)

getvariable(cache::VariableCache, i::ScalarIndex) = getvariable(cache.scalars, i)
getvariable(cache::VariableCache, x) = getvariable(cache.tensors, x)

function addvariable!(cache::VariableCache, x)
    if Capstan.isscalar(x)
        return addvariable!(cache.scalars, x)
    else
        return addvariable!(cache.tensors, x)
    end
end

Base.empty!(cache::VariableCache, options...) = (empty!(cache.tensors, options...); empty!(cache.scalars); cache)
