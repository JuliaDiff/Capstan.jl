####################
# AbstractVariable #
####################

abstract type AbstractVariable end

value(x) = x

incrdownstream!(x) = nothing

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

incrderiv!(x::ScalarVariable{T}, y) where {T} = (x.cache.derivs[x.index.index]::T += y; nothing)

###########
# Tensors #
###########

#=== TensorVariable ===#

struct TensorVariable{T} <: AbstractVariable
    value::T
    deriv::T
    downstream::RefValue{Int}
    TensorVariable(x::T) where {T} = new{T}(x, fill!(similar(x), zero(eltype(x)), RefValue(0))
end

value(x::TensorVariable) = x.value

deriv(x::TensorVariable) = x.deriv

incrdownstream!(x::TensorVariable) = (x.downstream[] += 1; nothing)

#=== TensorCache ===#

struct TensorCache
    variables::ObjectIdDict
    TensorCache() = new(ObjectIdDict())
end

hasvariable(cache::TensorCache, x) = haskey(cache.variables, x)

getvariable(cache::TensorCache, x) = cache.variables[x]::TensorVariable{typeof(x)}

function addvariable!(cache::TensorCache, x)
    @assert Capstan.istensor(x)
    cache.variables[x] = TensorVariable(x)
    return x
end

Base.empty!(cache::TensorCache) = (empty!(cache.variables); cache)

function Base.empty!(cache::TensorCache, keep::Vector{UInt})
    filter!(kv -> in(object_id(kv.first), keep), cache.variables)
    return cache
end

Base.delete!(cache::TensorCache, x) = (delete!(cache.variables, x); cache)

Base.length(cache::TensorCache) = length(cache.variables)

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

###############
# @propagate! #
###############

#=
Using a macro here allows for delayed evaluation and syntactic fusion for load/add
broadcast (i.e. the `.+=` can be fused with the interpolated `Δ` expression).
=#
macro propagate!(x, Δ)
    return esc(quote
        if isa($x, $ScalarVariable)
            $incrderiv!($x, $Δ)
        elseif isa($x, $TensorVariable)
            if $(x).downstream > 1
                $(x).deriv .+= $Δ
            else
                $(x).deriv .= $Δ
            end
        end
    end)
end
