

"""
    rid_generation(df, col_name, id_dict)
This function is for generating a research ID from a hash digest ID. That
is, for those cases in which we want to hash an ID (not salt) and preserve
linkages across data sets, it's nicer to have a numeric value rather than
64-character hash digest to look at. Note that using this function pre-supposes
that the rows of the data frame have been shuffled, as we do in the
`DeIdDataFrame()` construnctor. Otherwise, we risk potentially leaking some
information related to the order of the observations in the dataframes.

# Arguments
- `df::DataFrame`: The de-identified dataframe
- `col_name::Symbol`: The column containing the hash digest of the original ID
- `id_dict::Dict`: Dictionary with hash digest => research ID mapping
"""
function rid_generation(df, col_name::Symbol, id_dict::Dict{String, Int})
    n = DataFrames.nrow(df)
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
    hash_salt_column!(df, col_name, salt_dict)
This function is used to salt and hash columns containing unique identifiers.
Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing
values are left missing.

# Arguments
- `df::DataFrame`: The dataframe to be de-idenfied
- `col_name::Symbol`: Name of column to de-idenfy
- `salt_dict::Dict{String, Tuple{String, Symbol}}`: Dictionary where key is cleartext, and value is a Tuple with {salt, column name}
"""
function hash_salt_column!(df, col_name::Symbol, salt_dict::Dict{String, Tuple{String, Symbol}})
    n = DataFrames.nrow(df)
    res = Array{Union{String, Missing}, 1}(missing, n)

    for i = 1:n
        ismissing(df[i, col_name]) && continue

        cleartext = string(df[i, col_name])
        if haskey(salt_dict, df[i, col_name])
            salt = salt_dict[cleartext]
        else
            salt = randstring(16)
            salt_dict[cleartext] = (salt, col_name)
        end

        res[i] = bytes2hex(sha256(string(cleartext, salt)))
    end

    df[:, col_name] = res
    return nothing
end

"""
    hash_column!(df, col_name, salt_dict)
This function is used to hash columns containing identifiers.
Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing
values are left missing.

# Arguments
- `df::DataFrame`: The dataframe to be de-idenfied
- `col_name::Symbol`: Name of column to de-idenfy
"""
function hash_column!(df, col_name::Symbol)
    n = DataFrames.nrow(df)
    res = Array{Union{String, Missing}, 1}(missing, n)

    for i = 1:n
        ismissing(df[i, col_name]) && continue

        cleartext = string(df[i, col_name])
        res[i] = bytes2hex(sha256(cleartext))
    end

    df[:, col_name] = res
    return nothing
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

# Arguments
- `df::DataFrame`: Dataframe to be de-identified
- `logger::Memento.Logger`: This is our logger that writes logs to disk
- `hash_col_names::Array{Symbol,1}`: Array with names of columns to be hashed
- `salt_col_names::Array{Symbol,1}`: Array with names of columns to be salted _and_ hashed
- `id_cols::Array{Symbol,1}`: Array with names of columns to be turned in to research IDs
- `id_dicts::Dict{Symbol, Dict{String, Int}}`: This is a dictionary of dictionaries. The keys of the outer dictionary are the column names of ID variables. The values of the outer dictionary are dictionaries themselves with key-values being hash digest IDs => research IDs.
- `salt_dict::Dict{String, Tuple{String, Symbol}}`: Dictionary where key is cleartext, and value is a Tuple with {salt, column name}
"""
function hash_all_columns!(df::DataFrames.DataFrame,
                           logger::Memento.Logger,
                           hash_col_names::Array{Symbol, 1},
                           salt_col_names::Array{Symbol, 1},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Dict{Symbol, Dict{String, Int}},
                           salt_dict::Dict{String, Tuple{String, Symbol}})

    for col in hash_col_names
        Memento.info(logger, "$(Dates.now()) Hashing column $col")
        hash_column!(df, col)
    end

    for col in salt_col_names
        Memento.info(logger, "$(Dates.now()) Hashing and salting column $col")
        hash_salt_column!(df, col, salt_dict)
    end

    for col in id_cols
        if !haskey(id_dicts, col)
            Memento.info(logger, "$(Dates.now()) Creating Research ID lookup table for column $col")
            id_dicts[col] = Dict{String, Int}()
        end

        # Indicate that new column is just our Research ID column
        Memento.info(logger, "$(Dates.now()) Overwriting hexdigest of column $col with Research ID")
        df[col] = rid_generation(df, col, id_dicts[col])
        new_name = Symbol(string("rid_", col))

        Memento.info(logger, "$(Dates.now()) Renaming $col to Research ID $new_name")
        DataFrames.rename!(df, (col => new_name))
    end
end


hash_all_columns!(df::DataFrames.DataFrame,
                   logger::Memento.Logger,
                   hash_col_names::Array{Symbol, 1},
                   id_cols::Array{Symbol, 1},
                   id_dicts::Dict{Symbol, Dict{String, Int}}) = hash_all_columns!(df, logger, hash_col_names, [], id_cols, id_dicts, Dict())
