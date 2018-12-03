# de_identify.jl


struct DfConfig
    name::String
    filename::String
    hash_cols::Array{Symbol,1}
    salt_cols::Array{Symbol,1}
    dateshift_cols::Array{Symbol,1}
    drop_cols::Array{Symbol,1}
    rename_cols::Dict{Symbol,Symbol}
end


struct DeIdConfig
    project::String
    logfile::String
    outdir::String
    seed::Int
    df_configs::Array{DfConfig,1}
    max_days::Int
    primary_id::Symbol
end


function DeIdConfig(cfg_file::String)
    cfg = YAML.load(open(cfg_file))
    logfile = joinpath(cfg["log_path"], cfg["project"]*".log")
    num_dfs = length(cfg["datasets"])
    outdir = cfg["output_path"]
    pk = Symbol(cfg["primary_id"])

    seed = get(cfg, "project_seed", rand(1:1000))
    max_days = get(cfg, "max_dateshift_days", 30)

    # initialize DataFrame Configs for data sets
    df_configs = Array{DfConfig,1}(undef, num_dfs)

    # populate DF Configs
    for (i, ds) in enumerate(cfg["datasets"])
        name = ds["name"]
        filename = ds["filename"]
        rename_dict = Dict{Symbol,Symbol}()
        for pair in get(ds, "rename_cols", [])
            rename_dict[Symbol(pair["in"])] = Symbol(pair["out"])
        end
        hash_cols = map(Symbol, get(ds, "hash_cols", Array{String,1}()))
        salt_cols = map(Symbol, get(ds, "salt_cols", Array{String,1}()))
        dateshift_cols = map(Symbol,  get(ds, "dateshift_cols", Array{String,1}()))
        drop_cols = map(Symbol,  get(ds, "drop_cols", Array{String,1}()))
        df_configs[i] = DfConfig(name, filename, hash_cols, salt_cols, dateshift_cols, drop_cols, rename_dict)
    end

    return DeIdConfig(cfg["project"], logfile, outdir, seed, df_configs, max_days, pk)
end


struct DeIdDataFrame
    df::DataFrames.DataFrame
    hash_cols::Array{Symbol, 1}
    salt_cols::Array{Symbol, 1}
    dateshift_cols::Array{Symbol, 1}
end

"""
    DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, drop_cols, dateshift_dict, id_col, id_dicts, salt)

This is the constructor for our DeIdDataFrame objects. Note that the first entry
in the `id_col` is the primary identifier for the dataset and what we use for our lookup in the date-shift dictionary. Also
note that the `dateshift_dict` object stores the Research IDs as the keys, and
number of days that the participant (for example) ought to have their dates shifted.
The `id_dicts` argument is a dictionary containing other dictionaries that store
the hash digest of original IDs to our new research IDs.
"""
function DeIdDataFrame(df::DataFrames.DataFrame,
                       logger::Memento.Logger,
                       hash_cols::Array{Symbol, 1},
                       salt_cols::Array{Symbol, 1},
                       dateshift_cols::Array{Symbol, 1},
                       drop_cols::Array{Symbol, 1},
                       dateshift_dict::Dict{Int, Int},
                       id_col::Symbol,
                       id_dicts::Dict{Symbol, Dict{String, Int}},
                       salt_dict::Dict{Any, String})
    df_new = copy(df)

    # Here we shuffle the rows so that ID creation does not
    # preserve information about the individual records.
    n = DataFrames.DataFrames.nrow(df_new)
    Memento.info(logger, "$(Dates.now()) Shuffling $n rows")
    df_new = df_new[shuffle(1:n), :]

    for col in drop_cols
        Memento.info(logger, "$(Dates.now()) Dropping column $col")
        delete!(df_new, col)
    end

    hash_all_columns!(df_new, logger, hash_cols, salt_cols, id_col, id_dicts, salt_dict)

    dateshift_id = Symbol(string("rid_", id_col))
    dateshift_all_cols!(df_new, logger, dateshift_cols, dateshift_id, dateshift_dict)

    return DeIdDataFrame(df_new, hash_cols, salt_cols, dateshift_cols)
end


DeIdDataFrame(df::DataFrames.DataFrame,
               logger::Memento.Logger,
               hash_cols::Array{Symbol, 1},
               dateshift_cols::Array{Symbol, 1},
               dateshift_dict::Dict{Int, Int},
               id_col::Symbol,
               id_dicts::Dict{Symbol, Dict{String, Int}}) = DeIdDataFrame(df, logger, hash_cols, [], dateshift_cols, [], dateshift_dict, id_col, id_dicts, Dict())



# NOTE: This constructor uses a `DfConfig` struct to pass the configuration
# that defines the set of columns to be hashed, salted, and date shifted.
DeIdDataFrame(df::DataFrames.DataFrame,
               cfg::DfConfig,
               logger::Memento.Logger,
               dateshift_dict::Dict{Int, Int},
               id_col::Symbol,
               id_dicts::Dict{Symbol, Dict{String, Int}},
               salt_dict::Dict{Any, String}) = DeIdDataFrame(df, logger, cfg.hash_cols, cfg.salt_cols, cfg.dateshift_cols, cfg.drop_cols, dateshift_dict, id_col, id_dicts, salt_dict)




struct DeIdentified
    df_array::Array{DeIdDataFrame, 1}
    dateshift_dict::Dict{Int, Int}      # unique ID and num days
    salt_dict::Dict{Any, String}        # primary_identifier, salt
    id_dicts::Dict{Symbol, Dict{String, Int}}
    logger::Memento.Logger
    deid_config::DeIdConfig
end


"""
    DeIdentified(cfg)
This is the constructor for the `DeIdentified` struct. We use this type to store
arrays of `DeIdDataFrame` variables, while also keeping a common `salt_dict` and
`dateshift_dict` between `DeIdDataFrame`s. The `salt_dict` allows us to track
what salt was used on what cleartext. This is only necessary in the case of doing
re-identification. The `id_dicts` argument is a dictionary containing other
dictionaries that store the hash digest of original IDs to our new research IDs.
"""
function DeIdentified(cfg::DeIdConfig)
    num_dfs = length(cfg.df_configs)
    deid_dfs = Array{DeIdDataFrame,1}(undef, num_dfs)
    id_dicts = Dict{Symbol,Dict{String,Int}}()
    salt_dict = Dict{Any, String}()
    dateshift_dict = Dict{Int, Int}()


    # Set up our top-level logger
    # root_logger = Memento.getlogger()
    df_logger = Memento.getlogger("deidentify")
    logfile_roller = Memento.FileRoller(cfg.logfile)
    # push!(root_logger, DefaultHandler(logfile_roller))
    push!(df_logger, Memento.DefaultHandler(logfile_roller))

    Memento.info(df_logger, "$(Dates.now()) Logging session for project $(cfg.project)")

    Memento.info(df_logger, "$(Dates.now()) Setting seed for project $(cfg.project)")
    seed!(cfg.seed)

    # set_max_days!(cfg.max_days)    # Set global MAX_DATESHIFT_DAYS variable
    # Memento.info(df_logger, "MAX_DATESHIFT_DAYS is set to $MAX_DATESHIFT_DAYS")

    for (i, dfc) in enumerate(cfg.df_configs)
        Memento.info(df_logger, "$(Dates.now()) Reading dataframe from $(dfc.filename)")
        df = CSV.read(dfc.filename)

        DataFrames.rename!(df, dfc.rename_cols)

        @assert cfg.primary_id in getfield(getfield(df, :colindex), :names)

        deid_dfs[i] = DeIdDataFrame(df,
                                    dfc,
                                    df_logger,
                                    dateshift_dict,
                                    cfg.primary_id,
                                    id_dicts,
                                    salt_dict)
    end

    return DeIdentified(deid_dfs, dateshift_dict, salt_dict, id_dicts, df_logger, cfg)
end

"""
    deidentify(config_path)

Run entire pipelint: Processes configuration YAML file, de-identifies the data,
and writes the data to disk.  Returns the DeIdentified object.
"""
function deidentify(cfg_file::String)
    proj_config = DeIdConfig(cfg_file)
    deid = DeIdentified(proj_config)
    DeIdentification.write(deid)

    return deid
end
