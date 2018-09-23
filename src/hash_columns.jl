

"""
    rid_generation(df, col_name, id_dict)
This function is for generating a research ID from a hashdigest ID. That
is, for those cases in which we want to hash an ID (not salt) and preserve
linkages across data sets, it's nicer to have a numeric value rather than
64-character hash digest to look at. Note that using this function pre-supposes
that the rows of the data frame have been shuffled, as we do in the
DeIdDataFrame() construnctor. Otherwise, we risk potentially leaking some
information related to the order of the observations in the dataframes.
"""
function rid_generation(df, col_name::Symbol, id_dict::Dict{String, Int})
    n = nrow(df)
    new_ids = Array{Union{Int, Missing}, 1}(undef, n)
    for i = 1:n
        if ismissing(df[i, col_name])
            new_ids[i] = missing
        else
            if haskey(id_dict, df[i, col_name])
                new_ids[i] = id_dict[df[i, col_name]]
            else
                new_id = 1 + length(id_dict)
                id_dict[df[i, col_name]] = new_id
                new_ids[i] = new_id
            end
        end
    end
    new_ids
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
            res[i] = missing
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
    nothing
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
    nothing
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
        df[col] = rid_generation(df, col, id_dict[j])
        rename!(df, (col => new_name))
    end
end


function hash_all_columns!(df::DataFrame,
                           hash_col_names::Array{Symbol, 1},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Array{Dict{String, Int}, 1})

    for col in hash_col_names
        hash_column!(df, col)
    end

    # This next loop handles the ID columns for which we want
    # to convert the hexdigest in to a non-ridiculous ID.
    for (j, col) in enumerate(id_cols)

        df[col] = rid_generation(df, col, id_dicts[j])

        # Indicate that new column is just obfuscated old column
        new_name = Symbol(string("obf_", col))
        rename!(df, (col => new_name))
    end
end
