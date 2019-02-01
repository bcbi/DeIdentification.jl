module DeIdentification

export deidentify, ProjectConfig, DeIdDicts

import YAML
import JSON
import Tables
import CSV
import Dates
import SHA: bytes2hex, sha256
import Random: shuffle, randstring, seed!
import Memento

include("de_identify.jl")
include("exporting.jl")

"""
    deid_file!(dicts, file_config, project_config, logger)

FILL THIS IN
"""
function deid_file!(dicts::DeIdDicts, fc::FileConfig, pc::ProjectConfig, logger)

    # Initiate new file
    infile = CSV.File(fc.filename, dateformat = pc.dateformat)
    outfile = joinpath(pc.outdir, "deid_" * fc.name * "_" * string(Dates.now()) * "csv")

    ncol = length(infile.names)

    new_names = Vector{Symbol}()
    new_types = Vector{Type}()
    pk = false
    pcol = pc.primary_id

    Memento.info(logger, "$(Dates.now()) Renaming file columns")
    for i = 1:ncol
        n = infile.names[i]
        t = infile.types[i]

        if haskey(fc.rename_cols, n)
            push!(new_names, fc.rename_cols[n])
            push!(new_types, t)

            if fc.rename_cols[n] == pc.primary_id
                pk = true
                pcol = n
            end
        elseif get(fc.colmap, n, Missing) == Drop
            continue
        else
            push!(new_names, n)
            push!(new_types, t)
        end

        if n == pc.primary_id
            pk = true
        end
    end

    schema = Tables.Schema(new_names, new_types)


    Memento.info(logger, "$(Dates.now()) Checking for primary column")
    @assert pk==true "Primary ID must be present in file"

    # write header to file
    CSV.write(schema, [], outfile)

    # Process each row
    for row in infile
        outrow = []

        val = getoutput(dicts, Hash, getproperty(row, pcol), 0)
        pid = setrid(val, dicts)

        for col in infile.names
            colname = get(fc.rename_cols, col, col)

            action = get(fc.colmap, colname, Missing) ::Type
            # drop cols
            action == Drop && continue

            val = getoutput(dicts, action, getproperty(row, col), pid)

            if col == pcol
                val = pid
            end

            push!(outrow, val)
        end

        CSV.write(schema, [row], outfile, append=true)
    end

    return nothing
end



"""
    deidentify(cfg::ProjectConfig)
This is the constructor for the `DeIdentified` struct. We use this type to store
arrays of `DeIdDataFrame` variables, while also keeping a common `salt_dict` and
`dateshift_dict` between `DeIdDataFrame`s. The `salt_dict` allows us to track
what salt was used on what cleartext. This is only necessary in the case of doing
re-identification. The `id_dict` argument is a dictionary containing the hash
digest of the original primary ID to our new research IDs.
"""
function deidentify(cfg::ProjectConfig)
    num_files = length(cfg.file_configs)
    dicts = DeIdDicts(cfg.maxdays)

    # Set up our top-level logger
    logger = Memento.getlogger("deidentify")
    logfile_roller = Memento.FileRoller(cfg.logfile)
    push!(logger, Memento.DefaultHandler(logfile_roller))

    Memento.info(logger, "$(Dates.now()) Logging session for project $(cfg.name)")

    Memento.info(logger, "$(Dates.now()) Setting seed for project $(cfg.name)")
    seed!(cfg.seed)

    for (i, fc) in enumerate(cfg.file_configs)
        Memento.info(logger, "$(Dates.now()) ====================== Processing $(fc.name) ======================")

        Memento.info(logger, "$(Dates.now()) Reading data from $(fc.filename)")
        deid_file!(dicts, fc, cfg, logger)

    end

    write_dicts(dicts, logger, cfg.outdir)

    return dicts
end

"""
    deidentify(config_path)

Run entire pipeline: Processes configuration YAML file, de-identifies the data,
and writes the data to disk.  Returns the dictionaries containing the mappings.
"""
function deidentify(cfg_file::String)
    proj_config = ProjectConfig(cfg_file)
    return deidentify(proj_config)
end


end # module
