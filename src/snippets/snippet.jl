mutable struct Snippet <: GitLabType
    file_name::Union{String, Nothing}
    visibility::Union{String, Nothing}
    created_at::Union{Dates.DateTime, Nothing}
    updated_at::Union{Dates.DateTime, Nothing}
    # author:: TBD
    id::Union{Int, Nothing}
    title::Union{String, Nothing}
    project_id::Union{Int, Nothing}
    description::Union{String, Nothing}
    web_url::Union{HTTP.URI, Nothing}
end

# Snippet(data::Dict) = json2gitlab(Snippet, data)
function Snippet(data::Dict)
    # @show data
    json2gitlab(Snippet, data)
end
Snippet(id::AbstractString) = Snippet(Dict("id" => id))

namefield(snippet::Snippet) = snippet.id

###############
# API Methods #
###############

## creating #
##----------#

#@api_default snippet(api::GitLabAPI, snippet_obj::Snippet; options...) = snippet(api::GitLabAPI, name(snippet_obj); options...)

#@api_default function snippet(api::GitLabAPI, snippet_obj, sha = ""; options...)
#    !isempty(sha) && (sha = "/" * sha)
#    result = gl_get_json(api, "/snippets/$(name(snippet_obj))$sha"; options...)
#    g = Snippet(result)
#end

#@api_default function snippets(api::GitLabAPI, owner; options...)
#    results, page_data = gl_get_paged_json(api, "/users/$(name(owner))/snippets"; options...)
#    map(Snippet, results), page_data
#end

#@api_default function snippets(api::GitLabAPI; options...)
#    results, page_data = gl_get_paged_json(api, "/snippets/public"; options...)
#    return map(Snippet, results), page_data
#end

# modifying #
#-----------#

@api_default create_snippet(api::GitLabAPI, project; options...) = Snippet(gl_post_json(api, "/projects/$(project)/snippets"; options...))
#@api_default edit_snippet(api::GitLabAPI, snippet; options...) = Snippet(gl_patch_json(api, "/snippets/$(name(snippet))"; options...))
#@api_default delete_snippet(api::GitLabAPI, snippet; options...) = gl_delete(api, "/snippets/$(name(snippet))"; options...)

## stars #
##------#

#@api_default star_snippet(api::GitLabAPI, snippet; options...) = gl_put(api, "/snippets/$(name(snippet))/star"; options...)
#@api_default unstar_snippet(api::GitLabAPI, snippet; options...) = gl_delete(api, "/snippets/$(name(snippet))/star"; options...)

#@api_default function starred_snippets(api::GitLabAPI; options...)
#    results, page_data = gl_get_paged_json(api, "/snippets/starred"; options...)
#    return map(Snippet, results), page_data
#end

## forks #
##-------#

#@api_default create_snippet_fork(api::GitLabAPI, snippet::Snippet; options...) = Snippet(gl_post_json(api, "/snippets/$(name(snippet))/forks"; options...))

#@api_default function snippet_forks(api::GitLabAPI, snippet; options...)
#    results, page_data = gl_get_paged_json(api, "/snippets/$(name(snippet))/forks"; options...)
#    return map(Snippet, results), page_data
#end
