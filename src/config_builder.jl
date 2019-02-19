import REPL
using REPL.TerminalMenus
import DataStructures: OrderedDict

"""
    user_input(prompt::String="")::String

Read a string from STDIN. The trailing newline is stripped.

The prompt string, if given, is printed to standard output without a
trailing newline before reading input.
"""
function user_input(prompt::String, default::String)
    print(prompt)
    response = readline(stdin)
    if response == ""
        return default
    else
        return response
    end
end

function deid_col!(d::OrderedDict, col_nm::String)
    deid_types = ["Nothing", "Hash", "Hash & Salt", "Date Shift", "Drop"]
    col_types = ["", "hash_cols", "salt_cols", "dateshift_cols", "drop_cols"]

    menu = RadioMenu(deid_types, pagesize=5)
    choice = request("Deidentification Method:", menu)

    if choice == 1
        return nothing
    elseif choice == -1
        println("Menu canceled.")
        return nothing
    else
        push!(d[col_types[choice]], col_nm)
        return nothing
    end
end

function get_ds_dict(name::String, filename::String)
    d = OrderedDict()
    d["name"] = name
    d["filename"] = filename

    col_types = ["rename_cols", "hash_cols", "salt_cols", "dateshift_cols", "drop_cols"]
    for col in col_types
        d[col] = []
    end

    return d
end

function tidy_up!(d)
    col_types = ["rename_cols", "hash_cols", "salt_cols", "dateshift_cols", "drop_cols"]
    for col in col_types
        if d[col] == []
            delete!(d, col)
        end
    end
end

function print_yaml(io, yml::AbstractArray, indent::Int)
    firstval = true
    for item in yml
        if typeof(item) <: AbstractDict
            print_yaml(io, item, indent)
        else
            write(io, repeat(' ', indent), "- ", item, '\n')
        end
    end
end

function print_yaml(io, yml::AbstractDict, indent::Int)
    firstval = (indent > 0 ? true : false)
    for (k, v) in yml
        if typeof(v) <: AbstractArray
            write(io, repeat(' ', indent), k, ":", '\n')
            print_yaml(io, v, indent+2)
        else
            if firstval
                write(io, repeat(' ', indent), "- ")
                write(io, k, ": ", v, '\n')

                firstval = false
                indent += 2
            else
                write(io, repeat(' ', indent))
                write(io, k, ": ", v, '\n')
            end
        end
    end
end

function write_yaml(file::String, yml::AbstractDict)
    open(file, "w") do io
        indent = 0
        print_yaml(io, yml, indent)
    end
end


function build_config(data_dir::String, config_file::String)
    if !isfile(config_file)
        touch(config_file)
    end

    if !isdir(data_dir)
        @error "data_dir must be a directory containing datasets to be de-identified"
    end

    println("DeIdentification Config Builder")
    println("===============================")
    println("Follow the prompts to build a draft of your config file using the datasets.")
    println("The prompts are all written as 'Prompt [default] : '. If there is no default")
    println("the field is required.")
    println("NOTE: this builder will not ask about pre- or post-processing, add after if needed")
    if lowercase(user_input("Ready to get started? [y] ", "y"))[1] != 'y'
        return nothing
    else
        println("Great! Here we go...")
        println()
    end

    yml = OrderedDict()

    println("Let's start with the project level info")
    println("---------------------------------------")

    yml["project"] = user_input("Project name [$(splitpath(data_dir)[end])]: ", splitpath(data_dir)[end])
    yml["project_seed"] = user_input("Project seed [123]: (used for reproducibility) ", "123")
    yml["max_dateshift_days"] = user_input("Maximum Date Shift Days [30]: ", "30")
    yml["log_path"] = user_input("Path for logs [./logs]: ", "./logs")
    yml["output_path"] = user_input("Path for output files [./output]: ", "./output")
    yml["date_format"] = user_input("Input date format [y/m/d H:M:S]: ", "y/m/d H:M:S")

    yml["primary_id"] = ""
    while yml["primary_id"] == ""
        yml["primary_id"] = user_input("Primary ID Column Name: (REQUIRED - must be present in all datasets) ", "")
    end

    println("Now let's look at the data sets")
    println("-------------------------------")

    for (root, dirs, files) in walkdir(data_dir)
        yml["datasets"] = []

        for file in files

            nm = user_input("Dataset Name [$file]: ", file)
            fnm = joinpath(root,file)

            d = get_ds_dict(nm, fnm)

            f = CSV.File(joinpath(root, file), dateformat = yml["date_format"])

            for i in 1:length(f.names)
                println()
                orig_nm = string(f.names[i])
                println("[ ", orig_nm, " - ", string(f.types[i]), " ]")

                # rename col?
                col_nm = user_input("Column Name [$(orig_nm)]: ", orig_nm)
                if col_nm != orig_nm
                    push!(d["rename_cols"], OrderedDict("in"=>orig_nm, "out"=>col_nm))
                end

                # all others
                deid_col!(d, col_nm)
            end

            tidy_up!(d)

            push!(yml["datasets"], d)
        end
    end

    return yml

end
