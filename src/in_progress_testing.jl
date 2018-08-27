using DeIdentification
using CSV

data_dir = "/Users/pstey/projects_code/DeIdentification/data"

pat = CSV.read(joinpath(data_dir, "pat.csv"))
dx = CSV.read(joinpath(data_dir, "dx.csv"))
med = CSV.read(joinpath(data_dir, "med.csv"))




dat2 = DataFrame(id = [4, 6, 7, 3, 3, 6, 7],
                 x1 = rand(7),
                 x2 = ["cat", "dog", "dog", "fish", "bird", "cat", "dog"],
                 x3 = ["2018-02-22", "2018-05-11", "2018-09-20", "2014-03-12",
                       "2011-11-25", "2001-05-31", "1990-04-27"])


dat2[:x3] = DateTime.(dat2[:x3])
