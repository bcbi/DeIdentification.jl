

"""
    id_generation(df, col_name, id_dict)
This function is effectively for generating something like a research ID. That is,
for those cases in which we want to hash an ID (not salt) and preserve linkages
across data sets, it's nicer to have a numeric value rather than 64-character hash
digest to look at. Note that using this function pre-supposes that the rows of the
data frame have been shuffled, as we do in the DeIdDataFrame() construnctor. Otherwise,
we risk potentially leaking some information related to the order of the observations
in the dataframes.
"""
function id_generation(df, col_name::Symbol, id_dict::Dict{String, Int})
    n = nrow(df)
    res = Array{Union{Int, Missing}, 1}(undef, n)
    for i = 1:n
        if ismissing(df[i, col_name])
            res[i] = missing
        else
            if haskey(id_dict, df[i, col_name])
                res[i] = id_dict[df[i, col_name]]
            else
                new_id = 1 + length(id_dict)
                id_dict[df[i, col_name]] = new_id
                res[i] = new_id
            end
        end
    end
    res
end




"""
    hash_column!(df, col_name, salt_dict)
This function is used to salt and hash columns containing unique identifiers.
Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing
values are left missing. Also note that if `salt_dict` is passed, the method
dispatched assumes we are hashing _and_ salting.
"""
function hash_column!(df, col_name::Symbol, salt_dict::Dict{String, Tuple{String, Symbol}})
    n = nrow(df)
    res = Array{Union{String, Missing}, 1}(undef, n)

    for i = 1:n
        if ismissing(df[i, col_name])
            continue
        elseif haskey(salt_dict, df[i, col_name])
            cleartext = string(df[i, col_name])
            salt = salt_dict[cleartext]
            res[i] = bytes2hex(sha256(string(cleartext, salt)))
        else
            cleartext = string(df[i, col_name])
            salt = randstring(16)
            salt_dict[cleartext] = (salt, col_name)
            res[i] = bytes2hex(sha256(string(cleartext, salt)))
        end
    end

    df[:, col_name] = res
    return nothing
end


function hash_column!(df, col_name::Symbol)
    n = nrow(df)
    res = Array{Union{String, Missing}, 1}(undef, n)

    for i = 1:n
        if ismissing(df[i, col_name])
            continue
        else
            cleartext = string(df[i, col_name])
            res[i] = bytes2hex(sha256(cleartext))
        end
    end

    df[:, col_name] = res
    return nothing
end



"""
    hash_all_columns!(df, salt_dict, hash_col_names, salt_col_names)
This function simply iterates over columns to be hashed, those to be salted and
hashed, and those for which we want to generate sane-looking research IDs. Note
that the order of entries in the `id_cols` and `id_dicts` arrays must be match.
That is, the j-th Symbol in `id_cols` ought to the column name of the column
whose hashed values and research IDs live in the j-th dictionary of `id_dicts`.
"""
function hash_all_columns!(df::DataFrame,
                           hash_col_names::Array{Symbol, 1},
                           salt_col_names::Array{Symbol, 1},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Array{Dict{String, Int}, 1},
                           salt_dict::Dict{String, Tuple{String, Symbol}})

    for col in hash_col_names
        hash_column!(df, col)
    end

    for col in salt_col_names
        hash_column!(df, col, salt_dict)
    end

    for (j, col) in enumerate(id_cols)
        # Indicate that new column is just obfuscated old column
        new_name = Symbol(string("obf_", col))
        df[col] = id_generation(df, col, id_dict[j])
        rename!(df, (col => new_name))
    end
end
