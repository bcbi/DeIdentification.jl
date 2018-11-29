using DeIdentification
using DataFrames
using CSV
using YAML

using Test

# SET UP COMMON TEST VARIABLES AND ENVIRONMENT
test_file = "ehr_data.yml"
logpath = joinpath(@__DIR__, "logs")
outputpath = joinpath(@__DIR__, "output")

isdir(logpath) && rm(logpath, recursive=true)
isdir(outputpath) && rm(outputpath, recursive=true)

mkdir(joinpath(@__DIR__, "logs"))
mkdir(joinpath(@__DIR__, "output"))
# ----------------------------

@testset "config creation" begin
    cfg_raw = YAML.load_file(test_file)

    # nominally check YAML loading worked
    @test cfg_raw["project"] == "ehr"

    cfg = DeIdConfig(test_file)

    @test cfg_raw["project"] == cfg.project
    @test cfg_raw["datasets"][1]["name"] == cfg.df_configs[1].name
end

@testset "rid_generation" begin

    df1 = DataFrame(id = [4, 6, 7, 3, 3, 5, 7],
                    x1 = rand(7),
                    x2 = ["cat", "dog", "dog", "fish", "bird", "cat", "dog"],
                    x3 = ["2018-02-22", "2018-05-11", "2018-09-20", "2014-03-12",
                           "2011-11-25", "2001-05-31", "1990-04-27"])

    df2 = DataFrame(id = [6, 5, 3, 4, 5],
                   y1 = randn(5))

    # Check hashing and research ID generation
    id_dict = Dict{String, Int}()
    DeIdentification.hash_column!(df1, :id)
    DeIdentification.hash_column!(df2, :id)

    @test DeIdentification.rid_generation(df1, :id, id_dict) == [1, 2, 3, 4, 4, 5, 3]
    @test DeIdentification.rid_generation(df2, :id, id_dict) == [2, 5, 4, 1, 5]
end


@testset "integration_tests" begin
    proj_config = DeIdConfig(test_file)
    deid = DeIdentified(proj_config)

    @test typeof(deid) == DeIdentified

    @test isfile(joinpath(logpath,"ehr.log.0001"))

    DeIdentification.write(deid)

    @test isfile(joinpath(outputpath, "deid_dx.csv"))
    @test isfile(joinpath(outputpath, "salts.json"))
end

@testset "primary identifiter" begin
    cfg = DeIdConfig("ehr_data_bad_pk.yml")

    @test_throws AssertionError DeIdentified(cfg)
end

@testset "hash seeding" begin
    cfg1 = DeIdConfig(test_file)
    cfg2 = DeIdConfig("ehr_data_alt_seed.yml")

    deid1 = DeIdentified(cfg1)
    deid1a = DeIdentified(cfg1)
    deid2 = DeIdentified(cfg2)

    @test deid1.df_array[1].df == deid1a.df_array[1].df
    @test deid1.salt_dict == deid1a.salt_dict
    @test deid1.df_array[1].df != deid2.df_array[1].df
    @test deid1.salt_dict != deid2.salt_dict
end

# TEAR DOWN
rm(logpath, recursive=true)
rm(outputpath, recursive=true)
#--------------------------
