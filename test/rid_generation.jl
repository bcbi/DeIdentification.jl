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
    hash_column!(df1, :id)
    hash_column!(df2, :id)

    @test id_generation(df1, :id, id_dict) == [1, 2, 3, 4, 4, 5, 3]
    @test id_generation(df2, :id, id_dict) == [2, 5, 4, 1, 5]

end
