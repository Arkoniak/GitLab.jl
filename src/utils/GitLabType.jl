##############
# GitLabType #
##############
# A `GitLabType` is a Julia type representation of a JSON object defined by the
# GitLab API. Generally:
#
# - The fields of these types should correspond to keys in the JSON object. In
#   the event the JSON object has a "type" key, the corresponding field name
#   used should be `typ` (since `type` is a reserved word in Julia).
#
# - The method `name` should be defined on every GitLabType. This method
#   returns the type's identity in the form used for URI construction. For
#   example, `name` called on an `Owner` will return the owner's login, while
#   `name` called on a `Commit` will return the commit's sha.
#
# - A GitLabType's field types should be Nullables of either concrete types, a
#   Vectors of concrete types, or Dicts.

abstract type GitLabType end

# TODO a::T1, b::T2 where T
function Base.:(==)(a::GitLabType, b::GitLabType)
    if typeof(a) != typeof(b)
        return false
    end

    for field in fieldnames(a)
        aval, bval = getfield(a, field), getfield(b, field)
        if isnull(aval) == isnull(bval)
            if !(isnull(aval)) && get(aval) != get(bval)
                return false
            end
        else
            return false
        end
    end

    return true
end

# `namefield` is overloaded by various GitLabTypes to allow for more generic
# input to AP functions that require a name to construct URI paths via `name`
name(val) = val
name(g::GitLabType) = namefield(g)

########################################
# Converting JSON Dicts to GitLabTypes #
########################################

# Unwrap Union{Nothing, Foo} to just Foo
unwrap_union_types(T) = T
function unwrap_union_types(T::Union)
    if T.a == Nothing
        return T.b
    end
    return T.a
end

function extract_nullable(data::Dict, key, ::Type{T}) where {T}
    if haskey(data, key)
        val = data[key]
        if val !== nothing
            if T <: Vector
                V = eltype(T)
                return V[prune_gitlab_value(v, unwrap_union_types(V)) for v in val]
            else
                return prune_gitlab_value(val, unwrap_union_types(T))
            end
        end
    end
    return nothing
end

prune_gitlab_value(val::T, ::Type{Any}) where T = T(val)
prune_gitlab_value(val, ::Type{T}) where {T} = T(val)
prune_gitlab_value(val::AbstractString, ::Type{Dates.DateTime}) = Dates.DateTime(chopz(val))

# ISO 8601 allows for a trailing 'Z' to indicate that the given time is UTC.
# Julia's Dates.DateTime constructor doesn't support this, but GitLab's time
# strings can contain it. This method ensures that a string's trailing 'Z',
# if present, has been removed.
function chopz(str::T) where {T <: AbstractString}
    if !(isempty(str)) && last(str) == 'Z'
        return chop(str)
    end
    return str
end

# Calling `json2gitlab(::Type{G<:GitLabType}, data::Dict)` will parse the given
# dictionary into the type `G` with the expectation that the fieldnames of
# `G` are keys of `data`, and the corresponding values can be converted to the
# given field types.
@generated function json2gitlab(::Type{G}, data::Dict) where {G<:GitLabType}
    types = unwrap_union_types.(collect(G.types))
    fields = fieldnames(G)
    args = Vector{Expr}(undef, length(fields))
    for i in eachindex(fields)
        field, T = fields[i], types[i]
        key = field == :typ ? "type" : string(field)
        args[i] = :(extract_nullable(data, $key, $T))
    end
    return :(G($(args...))::G)
end

#############################################
# Converting GitLabType Dicts to JSON Dicts #
#############################################

gitlab2json(val) = val
gitlab2json(uri::HTTP.URI) = string(uri)
gitlab2json(dt::Dates.DateTime) = string(dt) * "Z"
gitlab2json(v::Vector) = [gitlab2json(i) for i in v]

function gitlab2json(g::GitLabType)
    results = Dict()
    for field in fieldnames(typeof(g))
        val = getfield(g, field)
        if val != nothing
            key = field == :typ ? "type" : string(field)
            results[key] = gitlab2json(val)
        end
    end
    return results
end

function gitlab2json(data::Dict{K}) where {K}
    results = Dict{K,Any}()
    for (key, val) in data
        results[key] = gitlab2json(val)
    end
    return results
end

###################
# Pretty Printing #
###################

function Base.show(io::IO, g::GitLabType)
    if get(io, :compact, false)
        uri_id = namefield(g)
        if uri_id === nothing
            print(io, typeof(g), "(…)")
        else
            print(io, typeof(g), "($(repr(uri_id)))")
        end
    else
        print(io, "$(typeof(g)) (all fields are Union{Nothing, T}):")
        for field in fieldnames(typeof(g))
            val = getfield(g, field)
            if !(val === nothing)
                println(io)
                print(io, "  $field: ")
                if isa(val, Vector)
                    print(io, typeof(val))
                else
                    show(IOContext(io, :compact => true), val)
                end
            end
        end
    end
end
