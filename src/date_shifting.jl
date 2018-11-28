import DataFrames

# function build_dateshift_dict(uniq_ids, max_days)
#     n = length(uniq_ids)
#     days = rand(1:max_days, n)
#     res = Dict(zip(uniq_ids, days))
#     return res
# end

function update_dateshift_dict!(dateshift_dict, id, max_days)
    n_days = rand(-max_days:max_days)
    dateshift_dict[id] = n_days
    nothing
end



# function format_timestamp(time_str::String)
#     res = DateTime(time_str, "yy/mm/dd H:M")
#     return res
# end


# begin
#     df1 = DataFrames.DataFrame(id = [4, 6, 7, 3, 3, 5, 7],
#                                x1 = rand(7),
#                                x2 = ["cat", "dog", "dog", "fish", "bird", "cat", "dog"],
#                                x3 = ["2018-02-22", "2018-05-11", "2018-09-20",       "2014-03-12", "2011-11-25", "2001-05-31", "1990-04-27"])
#
#     show(df1)
#     # Dates.DateTime(df1[1, :x3], "yy-mm-dd H:M") + Dates.Day(2)
#
#     function shift_datetime!(dt::Dates.DateTime, n_days::Int)
#         println(dt)
#         dt += Dates.Day(n_days)
#         println(dt)
#     end
#
#     shift_datetime!(Dates.DateTime(df1[3, :x3], "yy-mm-dd H:M"), 999)
#     show(df1)
# end


function shift_datetime!(dt::Dates.DateTime, n_days::Int)
    dt += Dates.Day(n_days)
end


function shift_datetime!(dt::Dates.Date, n_days::Int)
    dt += Dates.Day(n_days)
end


"""
    dateshift_col!(df, date_col, id_col, dateshift_dict)
This function is used internally by dateshift_all_cols!(). We require that
date shifting is done at the patient level. Thus, we pass the `id_col` to
ensure that for a given patient, all their encounter data are shifted by the
same `n_days`.

# Arguments
- `df::DataFrame`: The dataframe with the column to be date shifted
- `date_col::Symbol`: Column with dates to be shifted
- `id_col::Symbol`: Column with ID (e.g., patient ID) to find dateshift value for this observation
- `dateshift_dict::Dict`: Dictionary where keys are ID (e.g., patient ID) and values are integers by which to shift the date (i.e., a number of days)
- `max_days::Int`: The maximum number of days (positive or negative) that a date could be shifted
"""
function dateshift_col!(df::DataFrames.DataFrame, date_col::Symbol, id_col::Symbol, dateshift_dict::Dict, max_days::Int = 30)
    n = DataFrames.nrow(df)
    for i = 1:n
        id = df[i, id_col]        # Note, this is the processed "Research ID"
        if ismissing(id) || ismissing(df[i, date_col])
            continue
        else
            if haskey(dateshift_dict, id)
                n_days = dateshift_dict[id]
                df[i, date_col] = df[i, date_col] + n_days
            else
                update_dateshift_dict!(dateshift_dict, id, max_days)
            end
        end
    end
end


function dateshift_all_cols!(df, logger, dateshift_cols, id_col, dateshift_dict, max_days = 30)
    for col in dateshift_cols
        Memento.info(logger, "$(Dates.now()) Shifting dates for column $col")
        dateshift_col!(df, col, id_col, dateshift_dict, max_days)
    end
end


# HACK: This is a sub-optimal solution, but here we are. The function below
# is used to set a global variable that is used by the date shifting functions.
# This variable sets the max number of days that a given datetime can be shifted.
function set_max_days!(n)
    global MAX_DATESHIFT_DAYS = n
    nothing
end
