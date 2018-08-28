



function id_generation(hashed_ids, id_dict)
    n = length(hashed_ids)
    res = Array{Union{Int, Missing}, 1}(undef, n)
    for i = 1:n
        if ismissing(hashed_ids[i])
            res[i] = missing
        else
            if haskey(id_dict, hashed_ids[i])
                res[i] = id_dict[hashed_ids[i]]
            else
                new_id = 1 + length(id_dict)
                id_dict[hashed_ids[i]] = new_id
            end
        end
    end
    res
end




"""
    hash_column!(df, col_name, salt_dict)
This function is used to salt and hash columns containing unique identifiers. Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing values are left missing. Also note that if `salt_dict` is passed, the method dispatched assumes we are hashing _and_ salting.
"""
function hash_column!(df, col_name::Symbol, salt::String)
    n = nrow(df)
    res = Array{Union{String, Missing}, 1}(n)

    for i = 1:n
        if ismissing(df[i, col_name])
            continue
        else
            plaintext = string(df[i, col_name])
            res[i] = bytes2hex(sha256(string(plaintext, salt)))
        end
    end

    df[:, col_name] = res
    return nothing
end


function hash_column!(df, col_name::Symbol)
    n = nrow(df)
    res = Array{Union{String, Missing}, 1}(n)

    for i = 1:n
        if ismissing(df[i, col_name])
            continue
        else
            plaintext = string(df[i, col_name])
            res[i] = bytes2hex(sha256(plaintext))
        end
    end

    df[:, col_name] = res
    return nothing
end


function hash_column!(df, col_name::Symbol, id_dict::Dict{String, Int}, salt_dict::Dict{String, Tuple{String, Symbol}})
    n = nrow(df)
    res = Array{Union{String, Missing}, 1}(n)

    for i = 1:n
        if ismissing(df[i, col_name])
            continue
        else
            cleartext = string(df[i, col_name])

            if haskey(salt_dict, cleartext)
                salt = salt_dict[cleartext][1]
                res[i] = bytes2hex(sha256(string(cleartext, salt)))
            else
                # Update `salt_dict` if we don't find the cleartext
                salt = randstring(16)
                res[i] = bytes2hex(sha256(string(cleartext, salt)))

                salt_dict[cleartext] = (salt, col_name)
            end
        end
    end

    df[:, col_name] = res

    return nothing
end


"""
    hash_all_columns!(df, salt_dict, hash_col_names, salt_col_names)
This function simply iterates over `hash_col_names` and hashes and salts the content in the columns that are specified.
"""
function hash_all_columns!(df::DataFrame,
                           hash_col_names::Array{Symbol, 1},
                           salt_col_names::Array{Symbol, 1},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Array{Symbol, 1},
                           salt_dict::Dict{String, Tuple{String, Symbol}})

    for col in hash_col_names
        hash_column!(df, col)
    end

    for col in salt_col_names
        hash_column!(df, col, salt_dict)
    end
end
