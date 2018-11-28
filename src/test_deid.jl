using DeIdentification

using CSV
using DataFrames

"""
Function assumes that you have CSV files for identifiable and deidentified data in
separate directories. If this is not the case, please move the files accordingly
    --> PATH/identifiable
    --> PATH/deidentified
If you need to create deidentified data, use make_deid() in make_deid.jl

This function reuturns two similar dictionaries:
    df_dict - key is identifiable DataFrame, value is matching deidentified DataFrame
    orig2deid - key is identifiable CSV path, value is matching deidentified CSV path
"""
function grab_dfs()

    data_dir = "/Users/stephendove/Documents/Lifespan/edsn/DeIdentification/data"
    original_files = readdir(data_dir)
    output_dir = "/Users/stephendove/Documents/Lifespan/edsn/DeIdentification/output"
    deid_files = readdir(output_dir)
    deid_f = [file for file in deid_files if file[end-3:end]==".csv"]

    # Store CSVs
    orig2deid = Dict{String,String}()
    # Store dfs
    df_dict = Dict{DataFrames.DataFrame,DataFrames.DataFrame}()
    for orig in original_files
        for deid in deid_f
            if deid == "deid_" * orig
                orig2deid[data_dir * "/" * orig] = output_dir * "/" * deid
                df1 = CSV.File(data_dir * "/" * orig) |> DataFrames.DataFrame
                df2 = CSV.File(output_dir * "/" * deid) |> DataFrames.DataFrame
                df_dict[df1] = df2
            end
        end
    end

    return df_dict,orig2deid

end


println(df_dict)
