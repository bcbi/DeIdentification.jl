using DeIdentification
using DataFrames
using CSV
using YAML

using Test

@testset "Config" begin
    test_file = "ehr_data.yml"

    cfg_raw = YAML.load_file(test_file)

    # nominally check YAML loading worked
    @test cfg_raw["project"] == "ehr"

    cfg = DeIdConfig(test_file)

    @test cfg_raw["project"] == cfg.project
end
