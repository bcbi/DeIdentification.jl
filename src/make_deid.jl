using DeIdentification

using CSV
using DataFrames
using Dates
using YAML
using Random
using Memento
using JSON
using SHA

function make_deid()

    #data_dir = "/Users/pstey/projects_code/DeIdentification/data"
    data_dir2 = "/Users/stephendove/Documents/Lifespan/edsn/DeIdentification/data"
    working_dir = "/Users/stephendove/Documents/Lifespan/edsn/deidentification"

    cd(data_dir2)
    cfg = YAML.load(open("../test/ehr_data.yml"))
    println(cfg)

    proj_config = DeIdConfig("../test/ehr_data.yml")
    deid = DeIdentified(proj_config)
    write(deid)

    cd(working_dir)

end
