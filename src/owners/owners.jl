##############
# Owner Type #
##############


type Owner <: GitLabType
    name::Union{String, Nothing}
    username::Union{String, Nothing}
    id::Union{Int, Nothing}
    state::Union{String, Nothing}
    avatar_url::Union{HTTP.URI, Nothing}
    web_url::Union{HTTP.URI, Nothing}
    ownership_type::Union{String, Nothing} 

#=
    email::Union{String, Nothing}
    bio::Union{String, Nothing}
    company::Union{String, Nothing}
    location::Union{String, Nothing}
    gravatar_id::Union{String, Nothing}
    public_repos::Union{Int, Nothing}
    owned_private_repos::Union{Int, Nothing}
    total_private_repos::Union{Int, Nothing}
    public_gists::Union{Int, Nothing}
    private_gists::Union{Int, Nothing}
    followers::Union{Int, Nothing}
    following::Union{Int, Nothing}
    collaborators::Union{Int, Nothing}
    html_url::Union{HttpCommon.URI, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    date::Union{Dates.DateTime, Nothing}
    hireable::Union{Bool, Nothing}
    site_admin::Union{Bool, Nothing}
=#
end

function Owner(data::Dict) 
    o = json2gitlab(Owner, data)
    o.username == nothing ? o.ownership_type = "Organization" : o.ownership_type("User")
    o
end

Owner(username::AbstractString, isorg = false) = Owner(
    Dict("username" => isorg ? "" : username, 
         "name" => isorg ? username : "",
         "ownership_type" => isorg ? "Organization" : "User"))

namefield(owner::Owner) = isorg(owner) ? owner.name : owner.username

typprefix(isorg) = isorg ? "projects" : "users"

#############
# Owner API #
#############

isorg(owner::Owner) = owner.ownership_type == nothing ? true : owner.ownership_type == "Organization"

@api_default owner(api::GitLabAPI, owner_obj::Owner; options...) = owner(api, name(owner_obj), isorg(owner_obj); options...)

@api_default function owner(api::GitLabAPI, owner_obj, isorg = false; options...)
    ## TODO Need to look for a cleaner way of doing this ! Returns an array even while requesting a specific user
    if isorg
        result = gl_get_json(api, "/projects/search/$(owner_obj)"; options...)
        return Owner(result[1]["owner"])
    else
        result = gl_get_json(api, "/users?username=$(owner_obj)"; options...)
        return Owner(result[1])
    end
end

@api_default function users(api::GitLabAPI; options...)
    results, page_data = gl_get_paged_json(api, "/users"; options...)
    return map(Owner, results), page_data
end

@api_default function orgs(api::GitLabAPI, owner; options...)
    results, page_data = gl_get_paged_json(api, "/projects"; options...)
    return map(Owner, results), page_data
end

#= TODO: There seems to be no equivalent for these APIs 
function followers(owner; options...)
    results, page_data = gl_get_paged_json("/api/v3/users/$(name(owner))/followers"; options...)
    return map(Owner, results), page_data
end

function following(owner; options...)
    results, page_data = gl_get_paged_json("/api/v3/users/$(name(owner))/following"; options...)
    return map(Owner, results), page_data
end
=#

@api_default repos(api::GitLabAPI, owner::Owner; options...) = repos(api, name(owner), isorg(owner); options...)

@api_default function repos(api::GitLabAPI, owner, isorg = false; options...)
    results, page_data = gl_get_paged_json(api, "/projects/owned"; options...)
    return map(Repo, results), page_data
end
