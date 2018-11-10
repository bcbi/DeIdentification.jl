using DeIdentification


using CSV
using DataFrames
using Dates
using YAML
using Random
using Memento
using JSON


data_dir = "/Users/pstey/projects_code/DeIdentification/data"
data_dir2 = "/Users/stephendove/Documents/Lifespan/edsn/DeIdentification/data"
cd(data_dir)
cfg = YAML.load(open("../test/ehr_data.yml"))
println(cfg)


proj_config = DeIdConfig("../test/ehr_data.yml")

deid = DeIdentified(proj_config)
write(deid)













pat = CSV.read(joinpath(data_dir, "pat.csv"))
dx = CSV.read(joinpath(data_dir, "dx.csv"))
med = CSV.read(joinpath(data_dir, "med.csv"))


df1 = DataFrame(id = [4, 6, 7, 3, 3, 5, 7],
                x1 = rand(7),
                x2 = ["cat", "dog", "dog", "fish", "bird", "cat", "dog"],
                x3 = ["2018-02-22", "2018-05-11", "2018-09-20", "2014-03-12",
                       "2011-11-25", "2001-05-31", "1990-04-27"])

df2 = DataFrame(id = [6, 5, 3, 4, 5],
                y1 = randn(5))

df1[:x3] = DateTime.(df1[:x3])


# Check hashing and research ID generation
id_dict = Dict{String, Int}()
hash_column!(df1, :id)
hash_column!(df2, :id)

@assert id_generation(df1, :id, id_dict) == [1, 2, 3, 4, 4, 5, 3]
@assert id_generation(df2, :id, id_dict) == [2, 5, 4, 1, 5]

dateshift_dict = Dict{Int, Int}()
deid_df1 = DeIdDataFrame(df1,
                         hash_cols = [:id],
                         dateshift_cols = [:x3],
                         dateshift_dict = dateshift_dict,
                         id_cols = [:id],
                         id_dicts = [id_dict])
