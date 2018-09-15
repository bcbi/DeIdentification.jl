

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


# DateTime(dat[1,2], "yy/mm/dd H:M") + Dates.Day(2)

function shift_datetime!(dt::Dates.DateTime, n_days::Int)
    dt += Dates.Day(n_days)
end


"""
    dateshift_col!(df, date_col, id_col, dateshift_dict)
This function is used internally by dateshift_all_cols!(). We require that
date shifting is done at the patient level. Thus, we pass the `id_col` to
ensure that for a given patient, all their encounter data are shifted by the
same `n_days`.
"""
function dateshift_col!(df::DataFrame, date_col::Symbol, id_col, dateshift_dict, max_days = 30)
    n = nrow(df)
    for i = 1:n
        id = df[i, id_col]
        if ismissing(id)
            continue
        else
            if haskey(dateshift_dict, id)
                n_days = dateshift_dict[id]
                shift_datetime!(df[i, date_col], n_days)
            else
                @info("Adding the ID $id to the date-shift dictionary")
                update_dateshift_dict!(dateshift_dict, id, max_days)
            end
        end
    end
end


function dateshift_all_cols!(df, dateshift_cols, id_col, dateshift_dict, max_days = 30)
    for col in dateshift_cols
        dateshift_col!(df, col, id_col, dateshift_dict, max_days)
    end
end
