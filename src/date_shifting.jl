import DataFrames

function update_dateshift_dict!(dateshift_dict, id, max_days)
    n_days = rand(-max_days:max_days)
    dateshift_dict[id] = n_days
    
    return nothing
end

"""
    dateshift_col!(df, date_col, id_col, dateshift_dict)
This function is used internally by `dateshift_all_cols!()`. We require that
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

        (ismissing(id) || ismissing(df[i, date_col])) && continue

        !haskey(dateshift_dict, id) && update_dateshift_dict!(dateshift_dict, id, max_days)

        n_days = dateshift_dict[id]
        df[i, date_col] = df[i, date_col] + Dates.Day(n_days)
    end

    return nothing
end


function dateshift_all_cols!(df, logger, dateshift_cols, id_col, dateshift_dict, max_days = 30)
    for col in dateshift_cols
        Memento.info(logger, "$(Dates.now()) Shifting dates for column $col")
        dateshift_col!(df, col, id_col, dateshift_dict, max_days)
    end

    return nothing
end
