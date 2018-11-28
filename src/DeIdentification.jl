module DeIdentification

export DeIdentified, DeIdDataFrame, DeIdConfig, DfConfig

import YAML
import DataFrames
import CSV
import Dates: now
import SHA: bytes2hex, sha256
import Random: shuffle, randstring
import Memento: info


# logger = Memento.config!("info"; fmt="[{level} | {name}]: {msg}")
# push!(logger, DefaultHandler("deid_logfile.log"))


include("de_identify.jl")
include("utils.jl")
include("date_shifting.jl")
include("hash_columns.jl")
include("exporting.jl")

end # module
