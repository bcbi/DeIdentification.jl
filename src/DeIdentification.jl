module DeIdenficiation

export DeIdentified, DeIdDataFrame

using DataFrames
using SHA
using CSV
using Dates
using Random


include("utils.jl")
include("date_shifting.jl")
include("hash_columns.jl")
include("de_identify")




struct DeIdDataFrame
    df::DataFrame
    hash_cols::Array{Symbol, 1}
    salt_cols::Array{Symbol, 1}
    dateshift_cols::Array{Symbol, 1}
end


"""
    DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, dropped_cols, dateshift_dict, id_cols, id_dicts, salt)

"""
function DeIdDataFrame(df::DataFrame,
                       hash_cols::Array{Symbol, 1},
                       salt_cols::Array{Symbol, 1},
                       dateshift_cols::Array{Symbol, 1},
                       dropped_cols::Array{Symbol, 1},
                       dateshift_dict::Dict{DateTime, Int},
                       id_cols::Array{Symbol, 1},
                       id_dicts::Array{Dict{String, Int}, 1},
                       salt::String)
    df_new = copy(df)

    # Here we shuffle the rows so that ID creation does not
    # preserve information about the individual records.
    n = nrow(df_new)
    df_new = df_new[suffle(1:n), :]

    for col in dropped_cols
        delete!(df_new, col)
    end

    hash_all_columns!(df_new, hash_cols, salt_cols, id_cols, id_dicts, salt)
    dateshift_all_cols!(df_new, dateshift_cols, dateshift_dict)

    res = new(df_new, hash_cols, salt_cols, dateshift_cols)
    return res
end


struct DeIdentified
    df_array::Array{DeIdDataFrame, 1}
    dateshift_dict::Dict{String, Int}                 # unique ID and num days
    salt_dict::Dict{String, Tuple{String, Symbol}}    # cleartext, salt, col name

end


"""
    DeIdentified()
This is the constructor for the `DeIdentified` struct. We use this type to store arrays of `DeIdDataFrame` variables, while also keeping a common `salt_dict` and `dateshift_dict` between `DeIdDataFrame`s.
"""
function DeIdentified(salt)
    res = new(Array{DeIdDataFrame, 1}(0), Dict{String, Int}(0), salt)
    return res
end





end # module
