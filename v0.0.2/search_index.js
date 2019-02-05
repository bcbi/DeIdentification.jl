var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#DeIdentification.jl-1",
    "page": "Home",
    "title": "DeIdentification.jl",
    "category": "section",
    "text": "A Julia package for de-identifying CSV data sets.pages = [\n    \"Guide\" => \"usage.md\",\n    \"API\" => \"documentation.md\"\n    ]"
},

{
    "location": "#Quick-Notes:-1",
    "page": "Home",
    "title": "Quick Notes:",
    "category": "section",
    "text": "Compatible with julia 0.7 and 1.0\nIn your directory make sure to have the following sub-directories:\nlogs\noutput\nAll of the CSVs to be de-identified must contain a common identifier for the unit of analysis (e.g. patient ID)\nA config YAML file is required to run the pipeline"
},

{
    "location": "usage/#",
    "page": "Guide",
    "title": "Guide",
    "category": "page",
    "text": ""
},

{
    "location": "usage/#Usage-Guide-1",
    "page": "Guide",
    "title": "Usage Guide",
    "category": "section",
    "text": ""
},

{
    "location": "usage/#DeIdentification-Methods-1",
    "page": "Guide",
    "title": "DeIdentification Methods",
    "category": "section",
    "text": "Data can be processed in several different ways depending on the desired outputDropped: drop the column as it is not needed for analysis or as identifier\nHashed: obfuscate the data in the column, but maintain referential integrity for joining data\nHashed and Salted: obfuscate the data in the column, but do not maintain referential integrity for joining data (useful for columns that would only be needed in re-identifying data)\nDate Shifted: Shift date or datetime columns by a random value (all date/times related to the primary identifier will be shifted by the same random number)\nNothing: columns are not identifying data and do not need to be obfuscated"
},

{
    "location": "usage/#Config-YAML-1",
    "page": "Guide",
    "title": "Config YAML",
    "category": "section",
    "text": "To indicate how to de-identify the data, where the data lives, and other variables a configuration YAML file must be created by the user.# config.yml\nproject:                <project name> # required\nproject_seed:           <int>          # optional, but required for reproducibility\nlog_path:               <dir path>     # required, must already be created\nmax_dateshift_days:     <int>          # optional, default is 30\noutput_path:            <dir path>     # required, must already be created\n\n# The primary ID must be present in all data sets, so that date shifting and salting work appropriately\nprimary_id: <column name>       # required\n\n# 1 to n datasets must be present to de-identify\ndatasets:\n  - name: <dataset name 1>          # required, used to name output file\n    filename: <file path>         # required, path for input CSV\n    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing\n      - in: <col name 1a>                # required, current column name\n        out: <col name 1b>               # required, future column name\n    hash_cols:                    # optional, columns to be hashed\n      - <col name 1>\n      - <col name 2>\n    dateshift_cols:               # optional, columns to be dateshifted\n      - <col name 1>\n      - <col name 2>\n    salt_cols:                    # optional, columns to be hashed and salted\n      - <col name 1>\n      - <col name 2>\n    drop_cols:                    # optional, columns to be excluded from the de-identified data set\n      - <col name 1>\n      - <col name 2>\n  - name: <dataset name 2>          # required, used to name output file\n    filename: <file path>         # required, path for input CSV\n    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing\n      - in: <col name 1a>                # required, current column name\n        out: <col name 1b>               # required, future column name\n    hash_cols:                    # optional, columns to be hashed\n      - <col name 1>\n      - <col name 2>\n    dateshift_cols:               # optional, columns to be dateshifted\n      - <col name 1>\n      - <col name 2>\n    salt_cols:                    # optional, columns to be hashed and salted\n      - <col name 1>\n      - <col name 2>\n    drop_cols:                    # optional, columns to be excluded from the de-identified data set\n      - <col name 1>\n      - <col name 2>"
},

{
    "location": "usage/#Example-Config-1",
    "page": "Guide",
    "title": "Example Config",
    "category": "section",
    "text": "project:                \"ehr\"\nproject_seed:           42          # for reproducibility\nlog_path:               \"./logs\"\nmax_dateshift_days:     30\noutput_path:            \"./output\"\n\n# The primary ID must be present in all data sets, so that dateshifting and salting works appropriately\nprimary_id: \"CSN\"\n\ndatasets:\n  - name: dx\n    filename: \"./data/dx.csv\"\n    rename_cols:\n      - in: \"EncounterEpicCSN\"\n        out: \"CSN\"\n    hash_cols:\n      - \"CSN\"\n      - \"PatientPrimaryMRN\"\n    dateshift_cols:\n      - \"ArrivalDateandTime\"\n  - name: pat\n    filename: \"./data/pat.csv\"\n    # NOTE: renaming happens before any other operations (hashing, salting, dropping, dateshifting)\n    rename_cols:\n      - in: \"EncounterEpicCSN\"\n        out: \"CSN\"\n      - in: \"PatientLastName\"\n        out: \"last_name\"\n    hash_cols:\n      - \"CSN\"\n      - \"PatientPostalCode\"\n    salt_cols:\n      - \"last_name\"\n    dateshift_cols:\n      - \"ArrivalDateandTime\"\n      - \"DepartureDateandTime\"\n      - \"PatientBirthDate\"\n  - name: med\n    filename: \"./data/med.csv\"\n    rename_cols:\n      - in: \"EncounterEpicCSN\"\n        out: \"CSN\"\n    hash_cols:\n      - \"CSN\"\n    dateshift_cols:\n      - \"ArrivalDateandTime\"\n    drop_cols:\n      - \"MedicationTherapeuticClass\""
},

{
    "location": "usage/#Running-the-Pipeline-1",
    "page": "Guide",
    "title": "Running the Pipeline",
    "category": "section",
    "text": "To de-identify a data set, pass the config YAML to the deidentify function.deidentify(\"./config.yml\")This will read in the data, de-identify the data, write a log to file, and write the resulting data set to file.The pipeline consists of three main steps:Read the configuration file and process the settings\nDe-identify the data set\nWrite the de-identified data to filesThe deidentify function runs the three steps:proj_config = DeIdConfig(cfg_file)\ndeid = DeIdentified(proj_config)\nDeIdentification.write(deid)"
},

{
    "location": "documentation/#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "documentation/#DeIdentification.DeIdDataFrame-Tuple{DataFrames.DataFrame,Memento.Logger,Array{Symbol,1},Array{Symbol,1},Array{Symbol,1},Array{Symbol,1},Dict{Int64,Int64},Symbol,Dict{Symbol,Dict{String,Int64}},Dict{Any,String}}",
    "page": "API",
    "title": "DeIdentification.DeIdDataFrame",
    "category": "method",
    "text": "DeIdDataFrame(df, hash_cols, salt_cols, dateshift_cols, drop_cols, dateshift_dict, id_col, id_dicts, salt)\n\nThis is the constructor for our DeIdDataFrame objects. Note that the id_col is the primary identifier for the dataset and what we use for our lookup in the date-shift dictionary. Also note that the dateshift_dict object stores the Research IDs as the keys, and number of days that the participant (for example) ought to have their dates shifted. The id_dicts argument is a dictionary containing the hash digest of original IDs to our new research IDs.\n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.DeIdentified-Tuple{DeIdConfig}",
    "page": "API",
    "title": "DeIdentification.DeIdentified",
    "category": "method",
    "text": "DeIdentified(cfg)\n\nThis is the constructor for the DeIdentified struct. We use this type to store arrays of DeIdDataFrame variables, while also keeping a common salt_dict and dateshift_dict between DeIdDataFrames. The salt_dict allows us to track what salt was used on what cleartext. This is only necessary in the case of doing re-identification. The id_dicts argument is a dictionary containing other dictionaries that store the hash digest of the original primary IDs to our new research IDs.\n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.deidentify-Tuple{String}",
    "page": "API",
    "title": "DeIdentification.deidentify",
    "category": "method",
    "text": "deidentify(config_path)\n\nRun entire pipelint: Processes configuration YAML file, de-identifies the data, and writes the data to disk.  Returns the DeIdentified object.\n\n\n\n\n\n"
},

{
    "location": "documentation/#Base.write-Tuple{DeIdentified}",
    "page": "API",
    "title": "Base.write",
    "category": "method",
    "text": "write(deid)\n\nWrites DeIdentified structure to file. The datasets are outputted as CSVs, the dictionaries are written to josn. The files are written to the  output_path specified in the configuration YAML. \n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.dateshift_col!",
    "page": "API",
    "title": "DeIdentification.dateshift_col!",
    "category": "function",
    "text": "dateshift_col!(df, date_col, id_col, dateshift_dict)\n\nThis function is used internally by dateshift_all_cols!(). We require that date shifting is done at the patient level. Thus, we pass the id_col to ensure that for a given patient, all their encounter data are shifted by the same n_days.\n\nArguments\n\ndf::DataFrame: The dataframe with the column to be date shifted\ndate_col::Symbol: Column with dates to be shifted\nid_col::Symbol: Column with ID (e.g., patient ID) to find dateshift value for this observation\ndateshift_dict::Dict: Dictionary where keys are ID (e.g., patient ID) and values are integers by which to shift the date (i.e., a number of days)\nmax_days::Int: The maximum number of days (positive or negative) that a date could be shifted\n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.hash_all_columns!-Tuple{DataFrames.DataFrame,Memento.Logger,Array{Symbol,1},Array{Symbol,1},Symbol,Dict{Symbol,Dict{String,Int64}},Dict{Any,String}}",
    "page": "API",
    "title": "DeIdentification.hash_all_columns!",
    "category": "method",
    "text": "hash_all_columns!(df, salt_dict, hash_col_names, salt_col_names)\n\nThis function simply iterates over columns to be hashed, those to be salted and hashed, and those for which we want to generate sane-looking research IDs. Note that the id_dicts nested dictionary stores dictionaries for each column for which we have generated research IDs. Also note that this approach presumes if we have a column (e.g., :ssn) for which we generate a research ID in one dataframe, then all subsequent columns in other dataframes must have the same column name (i.e., :ssn).\n\nArguments\n\ndf::DataFrame: Dataframe to be de-identified\nlogger::Memento.Logger: This is our logger that writes logs to disk\nhash_col_names::Array{Symbol,1}: Array with names of columns to be hashed\nsalt_col_names::Array{Symbol,1}: Array with names of columns to be salted and hashed\nid_cols::Array{Symbol,1}: Array with names of columns to be turned in to research IDs\nid_dicts::Dict{Symbol, Dict{String, Int}}: This is a dictionary of dictionaries. The keys of the outer dictionary are the column names of ID variables. The values of the outer dictionary are dictionaries themselves with key-values being hash digest IDs => research IDs.\nsalt_dict::Dict{String, Tuple{String, Symbol}}: Dictionary where key is cleartext, and value is a Tuple with {salt, column name}\n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.hash_column!-Tuple{Any,Symbol}",
    "page": "API",
    "title": "DeIdentification.hash_column!",
    "category": "method",
    "text": "hash_column!(df, col_name, salt_dict)\n\nThis function is used to hash columns containing identifiers. Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing values are left missing.\n\nArguments\n\ndf::DataFrame: The dataframe to be de-idenfied\ncol_name::Symbol: Name of column to de-idenfy\n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.hash_salt_column!-Tuple{Any,Symbol,Symbol,Dict{Any,String}}",
    "page": "API",
    "title": "DeIdentification.hash_salt_column!",
    "category": "method",
    "text": "hash_salt_column!(df, col_name, salt_dict)\n\nThis function is used to salt and hash columns containing unique identifiers. Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing values are left missing.\n\nArguments\n\ndf::DataFrame: The dataframe to be de-idenfied\ncol_name::Symbol: Name of column to de-idenfy\nsalt_dict::Dict{String, Tuple{String, Symbol}}: Dictionary where key is cleartext, and value is a Tuple with {salt, column name}\n\n\n\n\n\n"
},

{
    "location": "documentation/#DeIdentification.rid_generation-Tuple{Any,Symbol,Dict{String,Int64}}",
    "page": "API",
    "title": "DeIdentification.rid_generation",
    "category": "method",
    "text": "rid_generation(df, col_name, id_dict)\n\nThis function is for generating a research ID from a hash digest ID. That is, for those cases in which we want to hash an ID (not salt) and preserve linkages across data sets, it\'s nicer to have a numeric value rather than 64-character hash digest to look at. Note that using this function pre-supposes that the rows of the data frame have been shuffled, as we do in the DeIdDataFrame() construnctor. Otherwise, we risk potentially leaking some information related to the order of the observations in the dataframes.\n\nArguments\n\ndf::DataFrame: The de-identified dataframe\ncol_name::Symbol: The column containing the hash digest of the original ID\nid_dict::Dict: Dictionary with hash digest => research ID mapping\n\n\n\n\n\n"
},

{
    "location": "documentation/#API-Reference-1",
    "page": "API",
    "title": "API Reference",
    "category": "section",
    "text": "Modules = [DeIdentification]"
},

]}