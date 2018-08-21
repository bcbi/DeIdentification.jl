# de_identify.jl

"""
    add_dataframe!(de_id, df, hash_cols, salt_cols, dateshift_cols)
This function adds a dataframe to a `DeIdentified` struct. It works one dataframe at a time. It is important to note that this function modifies the `deidentified`, the `salt_dict`
"""
function add_dataframe!(deid::DeIdentified, df::DataFrame, hash_cols, salt_cols, dateshift_cols)
    if df ∈ map(x -> x.df, deid.df_array)
        error("This dataframe is already incorporated in this DeIdentified object.")
    else
        df_deid = DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, deid.dateshift_dict, deid.salt)

        push!(deid.df_array, df_deid)
    end
end
