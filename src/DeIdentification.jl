module DeIdentification

export DeIdentified, DeIdDataFrame, DeIdConfig, DfConfig, deidentify

import YAML
import JSON
import DataFrames
import CSV
import Dates
import SHA: bytes2hex, sha256
import Random: shuffle, randstring, seed!
import Memento


# logger = Memento.config!("info"; fmt="[{level} | {name}]: {msg}")
# push!(logger, DefaultHandler("deid_logfile.log"))


include("de_identify.jl")
include("date_shifting.jl")
include("hash_columns.jl")
include("exporting.jl")

end # module
