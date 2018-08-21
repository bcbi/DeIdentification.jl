using DeIdentification
using CSV

filename = "/Users/pstey/projects_code/DeIdentification/data/dx.csv"
dat = CSV.read(filename)


dat2 = DataFrame(id = [4, 6, 7, 3, 3, 6, 7],
                 x1 = rand(7),
                 x2 = ["cat", "dog", "dog", "fish", "bird", "cat", "dog"],
                 x3 = ["2018-02-22", "2018-05-11", "2018-09-20", "2014-03-12",
                       "2011-11-25", "2001-05-31", "1990-04-27"])


dat2[:x3] = DateTime.(dat2[:x3])


# salts = Dict{String, Tuple{String, Symbol}}()
# hash_all_columns!(dat2, salts, [:id, :x2])
#
#
# salt_lkup = build_salt_dict(unique(dat[:patient_primary_mrn_ed_visit]))
# dat[:, 5] = hash_column!(dat[:, 5], salt_lkup)
