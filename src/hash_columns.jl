

"""
    rid_generation(df, col_name, id_dict)
This function is for generating a research ID from a hash digest ID. That
is, for those cases in which we want to hash an ID (not salt) and preserve
linkages across data sets, it's nicer to have a numeric value rather than
64-character hash digest to look at. Note that using this function pre-supposes
that the rows of the data frame have been shuffled, as we do in the
`DeIdDataFrame()` construnctor. Otherwise, we risk potentially leaking some
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
that the `id_dicts` nested dictionary stores dictionaries for each column for
which we have generated research IDs. Also note that this approach presumes if
we have a column (e.g., `:ssn`) for which we generate a research ID in one
dataframe, then all subsequent columns in other dataframes must have the same
column name (i.e., `:ssn`).
"""
function hash_all_columns!(df::DataFrames.DataFrame,
                           hash_col_names::Array{Symbol, 1},
                           salt_col_names::Array{Symbol, 1},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Dict{Symbol, Dict{String, Int}},
                           salt_dict::Dict{String, Tuple{String, Symbol}})

    for col in hash_col_names
        hash_column!(df, col)
    end

    for col in salt_col_names
        hash_column!(df, col, salt_dict)
    end

    for col in id_cols
        if !haskey(id_dicts, col)
            id_dicts[col] = Dict{String, Int}()
        end

        # Indicate that new column is just our Research ID column
        new_name = Symbol(string("rid_", col))
        df[col] = rid_generation(df, col, id_dicts[col])
        rename!(df, (col => new_name))
    end
end


function hash_all_columns!(df::DataFrames.DataFrame,
                           hash_col_names::Array{Symbol, 1},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Dict{Symbol, Dict{String, Int}})

    for col in hash_col_names
        hash_column!(df, col)
    end

    # This next loop handles the ID columns for which we want
    # to convert the hexdigest in to a non-ridiculous ID.
    for col in id_cols
        if !haskey(id_dicts, col)
            id_dicts[col] = Dict{String, Int}()
        end

        df[col] = rid_generation(df, col, id_dicts[col])

        # Indicate that new column is just our Research ID column
        new_name = Symbol(string("rid_", col))
        rename!(df, (col => new_name))
    end
end
