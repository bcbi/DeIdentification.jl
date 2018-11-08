@testset "integration_tests" begin
    proj_config = DeIdConfig("../test/ehr_data.yml")
    deid = DeIdentified(proj_config)

    @test typeof(deid) == DeIdentified
end
