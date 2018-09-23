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




"""
    DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, dropped_cols, dateshift_dict, id_cols, id_dicts, salt)

This is the struct for our DeIdDataFrame objects. Several points are
worth noting. First, the order of entries in the `id_cols` and `id_dicts` arrays
must be match. That is, the j-th Symbol in `id_cols` ought to the column name of
the column whose hashed values and research IDs live in the j-th dictionary of
`id_dicts`. Also, the first entry in the `id_cols` is what we use for our lookup
in the date-shift dictionary.
"""
struct DeIdDataFrame
    df::DataFrame
    hash_cols::Array{Symbol, 1}
    salt_cols::Array{Symbol, 1}
    dateshift_cols::Array{Symbol, 1}

    function DeIdDataFrame(df::DataFrame;
                           hash_cols::Array{Symbol, 1},
                           salt_cols::Array{Symbol, 1},
                           dateshift_cols::Array{Symbol, 1},
                           dropped_cols::Array{Symbol, 1},
                           dateshift_dict::Dict{DateTime, Int},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Array{Dict{String, Int}, 1},
                           salt_dict::Dict{String, Tuple{String, Symbol}})

        df_new = copy(df)

        # Here we shuffle the rows so that ID creation does not
        # preserve information about the individual records.
        n = nrow(df_new)
        df_new = df_new[shuffle(1:n), :]

        for col in dropped_cols
            delete!(df_new, col)
        end

        hash_all_columns!(df_new, hash_cols, salt_cols, id_cols, id_dicts, salt_dict)

        dateshift_id = Symbol(string("rid_", id_cols[1]))
        dateshift_all_cols!(df_new, dateshift_cols, dateshift_id, dateshift_dict)

        res = new(df_new, hash_cols, salt_cols, dateshift_cols)
        return res
    end


    function DeIdDataFrame(df::DataFrame;
                           hash_cols::Array{Symbol, 1},
                           dateshift_cols::Array{Symbol, 1},
                           dateshift_dict::Dict{Int, Int},
                           id_cols::Array{Symbol, 1},
                           id_dicts::Array{Dict{String, Int}, 1})
        df_new = copy(df)

        # Here we shuffle the rows so that ID creation does not
        # preserve information about the individual records.
        n = nrow(df_new)
        df_new = df_new[shuffle(1:n), :]

        hash_all_columns!(df_new, hash_cols, id_cols, id_dicts)

        dateshift_id = Symbol(string("rid_", id_cols[1]))
        dateshift_all_cols!(df_new, dateshift_cols, dateshift_id, dateshift_dict)

        res = new(df_new, hash_cols, Array{Symbol, 1}(), dateshift_cols)
        return res
    end
end



struct DeIdentified
    deid_config::DeIdConfig
    df_array::Array{DeIdDataFrame, 1}
    dateshift_dict::Dict{String, Int}                 # unique ID and num days
    salt_dict::Dict{String, Tuple{String, Symbol}}    # cleartext, salt, col name
end



"""
    DeIdentified()
This is the constructor for the `DeIdentified` struct. We use this type to store
arrays of `DeIdDataFrame` variables, while also keeping a common `salt_dict` and
`dateshift_dict` between `DeIdDataFrame`s.
"""
function DeIdentified()
    res = new(Array{DeIdDataFrame, 1}(),
              Dict{String, Int}(),
              Dict{String, Tuple{String, Symbol}}(),
              Dict{String, Tuple{String, Symbol}}())
    return res
end


struct DfConfig
    name::String
    filename::String
    hashed_cols::Array{Symbol,1}
    salted_cols::Array{Symbol,1}
    date_shift_cols::Array{Symbol,1}
end


struct DeIdConfig
    logfile::String
    seed::Int
    df_configs::Array{DfConfig,1}
end

function DeIdConfig(cfg_file::String)
    cfg = YAML.load(open(cfg_file))
    seed = cfg["project_seed"]
    logfile = joinpath(cfg["log_path"], cfg["project"]*".log")
    num_dfs = length(cfg["datasets"])

    df_configs = Array{DfConfig,1}(undef, num_dfs)

    for i = 1:num_dfs
        name = first(keys(cfg["datasets"][i]))
        filename = cfg["datasets"][i][name][1]["filename"]
        hash_cols = map(Symbol, get(cfg["datasets"][i][name][2], "hashed_cols", Array{String,1}()))
        salt_cols = map(Symbol, get(cfg["datasets"][i][name][3], "salted_cols", Array{String,1}()))
        date_shift_cols = map(Symbol,  get(cfg["datasets"][i][name][4], "date_shift_cols", Array{String,1}()))
        println(name)
        df_configs[i] = DfConfig(name, filename, hash_cols, salt_cols, date_shift_cols)
    end
    return DeIdConfig(logfile, seed, df_configs)
end




end # module
