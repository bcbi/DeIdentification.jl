# de_identify.jl


struct DfConfig
    name::String
    filename::String
    hash_cols::Array{Symbol,1}
    salt_cols::Array{Symbol,1}
    dateshift_cols::Array{Symbol,1}
    drop_cols::Array{Symbol,1}
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
        hash_cols = map(Symbol, get(cfg["datasets"][i][name][2], "hash_cols", Array{String,1}()))
        salt_cols = map(Symbol, get(cfg["datasets"][i][name][3], "salt_cols", Array{String,1}()))
        dateshift_cols = map(Symbol,  get(cfg["datasets"][i][name][4], "dateshift_cols", Array{String,1}()))
        drop_cols = map(Symbol,  get(cfg["datasets"][i][name][5], "drop_cols", Array{String,1}()))
        df_configs[i] = DfConfig(name, filename, hash_cols, salt_cols, dateshift_cols, drop_cols)
    end
    return DeIdConfig(logfile, seed, df_configs)
end


struct DeIdDataFrame
    df::DataFrames.DataFrame
    hash_cols::Array{Symbol, 1}
    salt_cols::Array{Symbol, 1}
    dateshift_cols::Array{Symbol, 1}
end

"""
    DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, drop_cols, dateshift_dict, id_cols, id_dicts, salt)

This is the constructor for our DeIdDataFrame objects. Note that the first entry
in the `id_cols` is what we use for our lookup in the date-shift dictionary. Also
note that the `dateshift_dict` object stores the Research IDs as the keys, and
number of days that the participant (for example) out to have their dates shifted.
"""
function DeIdDataFrame(df::DataFrames.DataFrame;
                       hash_cols::Array{Symbol, 1},
                       salt_cols::Array{Symbol, 1},
                       dateshift_cols::Array{Symbol, 1},
                       drop_cols::Array{Symbol, 1},
                       dateshift_dict::Dict{Int, Int},
                       id_cols::Array{Symbol, 1},
                       id_dicts::Dict{Symbol, Dict{String, Int}},
                       salt_dict::Dict{String, Tuple{String, Symbol}})

    df_new = copy(df)

    # Here we shuffle the rows so that ID creation does not
    # preserve information about the individual records.
    n = nrow(df_new)
    df_new = df_new[shuffle(1:n), :]

    for col in drop_cols
        delete!(df_new, col)
    end

    hash_all_columns!(df_new, hash_cols, salt_cols, id_cols, id_dicts, salt_dict)

    dateshift_id = Symbol(string("rid_", id_cols[1]))
    dateshift_all_cols!(df_new, dateshift_cols, dateshift_id, dateshift_dict)

    res = DeIdDataFrame(df_new, hash_cols, salt_cols, dateshift_cols)
    return res
end


function DeIdDataFrame(df::DataFrames.DataFrame;
                       hash_cols::Array{Symbol, 1},
                       dateshift_cols::Array{Symbol, 1},
                       dateshift_dict::Dict{Int, Int},
                       id_cols::Array{Symbol, 1},
                       id_dicts::Dict{Symbol, Dict{String, Int}})
    df_new = copy(df)

    # Here we shuffle the rows so that ID creation does not
    # preserve information about the individual records.
    n = nrow(df_new)
    df_new = df_new[shuffle(1:n), :]

    hash_all_columns!(df_new, hash_cols, id_cols, id_dicts)

    dateshift_id = Symbol(string("rid_", id_cols[1]))
    dateshift_all_cols!(df_new, dateshift_cols, dateshift_id, dateshift_dict)

    res = DeIdDataFrame(df_new, hash_cols, Array{Symbol, 1}(), dateshift_cols)
    return res
end


# NOTE: This constructor uses a `DfConfig` struct to pass the configuration
# that defines the set of columns to be hashed, salted, and date shifted.
function DeIdDataFrame(df::DataFrames.DataFrame,
                       cfg::DfConfig;
                       dateshift_dict::Dict{Int, Int},
                       id_cols::Array{Symbol, 1},
                       id_dicts::Dict{Symbol, Dict{String, Int}},
                       salt_dict::Dict{String, Tuple{String, Symbol}})

    df_new = copy(df)

    # Here we shuffle the rows so that ID creation does not
    # preserve information about the individual records.
    n = nrow(df_new)
    df_new = df_new[shuffle(1:n), :]

    for col in cfg.drop_cols
        delete!(df_new, col)
    end

    hash_all_columns!(df_new, cfg.hash_cols, cfg.salt_cols, id_cols, id_dicts, salt_dict)

    dateshift_id = Symbol(string("rid_", id_cols[1]))
    dateshift_all_cols!(df_new, cfg.dateshift_cols, dateshift_id, dateshift_dict)

    res = DeIdDataFrame(df_new, cfg.hash_cols, cfg.salt_cols, cfg.dateshift_cols)
    return res
end



struct DeIdentified
    df_array::Array{DeIdDataFrame, 1}
    dateshift_dict::Dict{Int, Int}                 # unique ID and num days
    salt_dict::Dict{String, Tuple{String, Symbol}}    # cleartext, salt, col. name
    deid_config::DeIdConfig
end


"""
    DeIdentified()
This is the constructor for the `DeIdentified` struct. We use this type to store
arrays of `DeIdDataFrame` variables, while also keeping a common `salt_dict` and
`dateshift_dict` between `DeIdDataFrame`s.
"""
function DeIdentified()
    res = DeIdentified(Array{DeIdDataFrame, 1}(),
                       Dict{Int, Int}(),
                       Dict{String, Tuple{String, Symbol}}(),
                       deid_config::DeIdConfig)
    return res
end


function DeIdentified(cfg::DeIdConfig)
    num_dfs = length(cfg.df_configs)
    deid_dfs = Array{DeIdDataFrame,1}(undef, num_dfs)
    id_dicts = Dict{Symbol,Dict{String,Int}}()
    salt_dict = Dict{String, Tuple{String, Symbol}}()
    dateshift_dict = Dict{Int, Int}()
    for i = 1:num_dfs
        df = CSV.read(cfg.df_configs[i].filename)
        deid_dfs[i] = DeIdDataFrame(df,
                                    cfg.df_configs[i],
                                    dateshift_dict = dateshift_dict,
                                    id_cols = cfg.df_configs[i].hash_cols,
                                    id_dicts = id_dicts,
                                    salt_dict = salt_dict)
    end
    res = DeIdentified(deid_dfs, dateshift_dict, salt_dict, cfg)
    res
end



"""
    add_dataframe!(de_id, df, hash_cols, salt_cols, dateshift_cols)

This function adds a dataframe to a `DeIdentified` struct. It works one dataframe
at a time. It is important to note that this function modifies the `deidentified`
and the `salt_dict` objects.
"""
function add_dataframe!(deid::DeIdentified, df::DataFrames.DataFrame, hash_cols, salt_cols, dateshift_cols)
    if df ∈ map(x -> x.df, deid.df_array)
        error("This dataframe is already incorporated in this DeIdentified object.")
    else
        df_deid = DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, deid.dateshift_dict, deid.salt)

        push!(deid.df_array, df_deid)
    end
end
