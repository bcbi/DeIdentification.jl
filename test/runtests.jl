using DeIdentification
using DataFrames
using CSV

using Base.Test

dx = CSV.read("../data/dx.csv")
med = CSV.read("../data/med.csv")
pat = CSV.read("../data/pat.csv")



@test 1 == 1
