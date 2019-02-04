using DeIdentification
using CSV
using YAML
using DataFrames
using Dates

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

    cfg = ProjectConfig(test_file)

    @test cfg_raw["project"] == cfg.name
    @test cfg_raw["datasets"][1]["name"] == cfg.file_configs[1].name
end

@testset "rid_generation" begin

    ids1 = [4, 6, 7, 3, 3, 5, 7]

    ids2 = [6, 5, 3, 4, 5]

    # Check hashing and research ID generation
    dicts = DeIdDicts(30)
    hash1 = map( x-> DeIdentification.getoutput(dicts, DeIdentification.Hash, x, 0), ids1)
    hash2 = map( x-> DeIdentification.getoutput(dicts, DeIdentification.Hash, x, 0), ids2)

    rid1 = map( x-> DeIdentification.setrid(x, dicts), hash1)
    rid2 = map( x-> DeIdentification.setrid(x, dicts), hash2)

    @test rid1 == [1, 2, 3, 4, 4, 5, 3]
    @test rid2 == [2, 5, 4, 1, 5]
end


@testset "integration_tests" begin
    proj_config = ProjectConfig(test_file)
    deid = deidentify(proj_config)

    @test typeof(deid) == DeIdDicts

    @test isfile(joinpath(logpath,"ehr.log.0001"))

    dx = false
    salts = false
    df = DataFrame()
    for (root, dirs, files) in walkdir(outputpath)
        for file in files
            if occursin(r"^deid_dx_.*csv", file)
                dx = true
                df = CSV.read(joinpath(root,file))
            elseif occursin(r"salts_.*json", file)
                salts = true
            end
        end
    end

    dfo = CSV.read(joinpath(@__DIR__, "data", "dx.csv"))

    # test column name change
    @test in(:EncounterEpicCSN, getfield(getfield(dfo, :colindex),:names))
    @test in(:CSN, getfield(getfield(df, :colindex),:names))

    # test that hash column was hashed
    @test length(df[1, :PatientPrimaryMRN]) == 64

    # test that dateshifted column was dateshifted
    @test df[1,:ArrivalDateandTime] != dfo[1,:ArrivalDateandTime]
    println(Dates.days(abs(df[1,:ArrivalDateandTime] - dfo[1,:ArrivalDateandTime])))
    @test Dates.days(abs(df[1,:ArrivalDateandTime] - dfo[1,:ArrivalDateandTime])) <= proj_config.maxdays

    # test that files were created as expected
    @test dx == true
    @test salts == true
end

@testset "primary identifiter" begin
    cfg = ProjectConfig("ehr_data_bad_pk.yml")

    @test_throws AssertionError deidentify(cfg)
end

@testset "hash seeding" begin
    cfg1 = ProjectConfig(test_file)
    cfg2 = ProjectConfig("ehr_data_alt_seed.yml")

    deid1 = deidentify(cfg1)
    deid1a = deidentify(cfg1)
    deid2 = deidentify(cfg2)

    @test deid1.salt == deid1a.salt
    @test deid1.salt != deid2.salt
end

# TEAR DOWN
rm(logpath, recursive=true)
rm(outputpath, recursive=true)
# --------------------------
