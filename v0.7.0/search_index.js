var documenterSearchIndex = {"docs":
[{"location":"usage/#Usage-Guide-1","page":"Guide","title":"Usage Guide","text":"","category":"section"},{"location":"usage/#DeIdentification-Methods-1","page":"Guide","title":"DeIdentification Methods","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Data can be processed in several different ways depending on the desired output","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Dropped: drop the column as it is not needed for analysis or as identifier\nHashed: obfuscate the data in the column, but maintain referential integrity for joining data\nHashed and Salted: obfuscate the data in the column, but do not maintain referential integrity for joining data (useful for columns that would only be needed in re-identifying data)\nDate Shifted: Shift date or datetime columns by a random value (all date/times related to the primary identifier will be shifted by the same random number), optionally add a static year value to all dates","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Data can also be transformed before or after deidentification","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Preprocess: before deidentification (e.g. hash), transform the data (e.g. make sure zip codes are 5 digit)\nPostprocess: after deidentficiation (e.g. dateshift) transform the data (e.g. only include the year of the date)","category":"page"},{"location":"usage/#Config-YAML-1","page":"Guide","title":"Config YAML","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"To indicate how to de-identify the data, where the data lives, and other variables a configuration YAML file must be created by the user. There is a build_config utility function which can walk a user through file creation for the basic deidentification methods.  Pre- and post- processing must be manually added to the .yml file.   It's possible to combine different datasets in the same config file, each dataset will follow the set of rules defined in the dataset block. In addition, multiple files of the same dataset can be processed at the same time by using Glob patterns in the filename field instead of the full file path.","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"# config.yml\nproject:                <project name> # required\nproject_seed:           <int>          # optional, but required for reproducibility\nlog_path:               <dir path>     # required, must already be created\nmax_dateshift_days:     <int>          # optional, default is 30\ndateshift_years:        <int>          # optional, default is 0\noutput_path:            <dir path>     # required, must already be created\n\n# The primary ID must be present in all data sets, so that date shifting and salting work appropriately\nprimary_id: <column name>       # required\n\n# Default date format is \"y-m-dTH:M:S.s\" (e.g. 1999-05-21T11:23:56.0123) - see Dates.DateFormat for options\ndate_format: <Dates.DateFormat>\n\n# 1 to n datasets must be present to de-identify\ndatasets:\n  - name: <dataset name 1>          # required, used to name output file\n    filename: <file path / glob pattern>         # required, path for input CSV, or Glob pattern for input files in folder.\n    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing\n      - in: <col name 1a>                # required, current column name\n        out: <col name 1b>               # required, future column name\n    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string\n    preprocess_cols:\n      - col: <col name>\n        transform: <expression>\n    hash_cols:                    # optional, columns to be hashed\n      - <col name 1>\n      - <col name 2>\n    dateshift_cols:               # optional, columns to be dateshifted\n      - <col name 1>\n      - <col name 2>\n    salt_cols:                    # optional, columns to be hashed and salted\n      - <col name 1>\n      - <col name 2>\n    drop_cols:                    # optional, columns to be excluded from the de-identified data set\n      - <col name 1>\n      - <col name 2>\n    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string\n    postprocess_cols:\n      - col: <col name>\n        transform: <expression>\n  - name: <dataset name 2>          # required, used to name output file\n    filename: <file path / glob pattern>         # required, path for input CSV, or Glob pattern for input files in folder.\n    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing\n      - in: <col name 1a>                # required, current column name\n        out: <col name 1b>               # required, future column name\n    hash_cols:                    # optional, columns to be hashed\n      - <col name 1>\n      - <col name 2>\n    dateshift_cols:               # optional, columns to be dateshifted\n      - <col name 1>\n      - <col name 2>\n    salt_cols:                    # optional, columns to be hashed and salted\n      - <col name 1>\n      - <col name 2>\n    drop_cols:                    # optional, columns to be excluded from the de-identified data set\n      - <col name 1>\n      - <col name 2>","category":"page"},{"location":"usage/#Example-Config-1","page":"Guide","title":"Example Config","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"project:                \"ehr\"\nproject_seed:           42          # for reproducibility\nlog_path:               \"./logs\"\nmax_dateshift_days:     30\ndateshift_years:        100\noutput_path:            \"./output\"\n\n# The primary ID must be present in all data sets, so that dateshifting and salting works appropriately\nprimary_id: \"CSN\"\n\n# Default date format is \"y-m-dTH:M:S.s\" (e.g. 1999-05-21T11:23:56.0000) - see Dates.DateFormat for options\ndate_format: \"y-m-dTH:M:S.s\"\n\ndatasets:\n  - name: dx\n    filename: \"./data/dx_files/*\" # Glob pattern option\n    rename_cols:\n      - in: \"EncounterBrownCSN\"\n        out: \"CSN\"\n    hash_cols:\n      - \"CSN\"\n      - \"PatientPrimaryMRN\"\n    dateshift_cols:\n      - \"ArrivalDateandTime\"\n    drop_cols:\n      - \"DiagnosisTerminologyType\"\n  - name: pat\n    filename: \"./data/pat.csv\"\n    # NOTE: renaming happens before any other operations (pre-processing, hashing, salting, dropping, dateshifting, post-processing)\n    rename_cols:\n      - in: \"EncounterBrownCSN\"\n        out: \"CSN\"\n      - in: \"PatientLastName\"\n        out: \"last_name\"\n    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string\n    preprocess_cols:\n      - col: \"PatientPostalCode\"\n        transform: \"getindex(VAL, 1:5)\"\n    hash_cols:\n      - \"CSN\"\n      - \"PatientPostalCode\"\n    salt_cols:\n      - \"last_name\"\n    dateshift_cols:\n      - \"ArrivalDateandTime\"\n      - \"DepartureDateandTime\"\n      - \"PatientBirthDate\"\n    # NOTE: VAL must be used to indicate the field value being transformed - no matter the field's type, VAL will be processed as a string\n    postprocess_cols:\n      - col: \"PatientBirthDate\"\n        transform: \"max(2000+100, parse(Int, getindex(VAL, 1:4)))\"\n  - name: med\n    filename: \"./data/med.csv\"\n    rename_cols:\n      - in: \"EncounterBrownCSN\"\n        out: \"CSN\"\n    hash_cols:\n      - \"CSN\"\n    dateshift_cols:\n      - \"ArrivalDateandTime\"\n    drop_cols:\n      - \"MedicationTherapeuticClass\"","category":"page"},{"location":"usage/#Generating-the-Configuration-1","page":"Guide","title":"Generating the Configuration","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Although the configuration YAML file can be put together by hand, there are also tools to help assist in the generation of a configuration file under different circumstances. Note, however, that in any circumstance, it is likely necessary to hand-edit the generated YAML file after processing to ensure everything is correct and to setup any pre- and post-processing necessary.","category":"page"},{"location":"usage/#Build-Configuration-Interactively-1","page":"Guide","title":"Build Configuration Interactively","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"If you have all the necessary data already in CSV format, you can use the build_config function to generate the configuration. This will prompt you for the necessary configuration actions for each column found in the CSV files. An interactive session might look like the below:","category":"page"},{"location":"usage/#Example-Interactive-Session-1","page":"Guide","title":"Example Interactive Session","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"julia --project=@. -e 'using DeIdentification; build_config(\"./test/data\", \"test.yaml\")'\n\nDeIdentification Config Builder\n===============================\nFollow the prompts to build a draft of your config file using the datasets.\nThe prompts are all written as 'Prompt [default]: '. If there is no default\nthe field is required.\nNOTE: this builder will not ask about pre- or post-processing, add after if needed\nReady to get started? [y]\nGreat! Here we go...\n\nLet's start with the project level info\n---------------------------------------\nProject name [data]:\nProject seed [2809867404]: (used for reproducibility)\nMaximum Date Shift Days [30]:\nYears to add to all dates [0]:\nPath for logs [./logs]:\nPath for output files [./output]:\nInput date format [y-m-dTH:M:S.s]:\nPrimary ID Column Name: (REQUIRED - must be present in all datasets) CSN\n\nNow let's look at the data sets\n-------------------------------\nDataset Name [dx]:\n\n[  ArrivalDateandTime - Dates.DateTime  ]\nColumn Name [ArrivalDateandTime]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n > Date Shift\n   Drop\n\n[  EncounterBrownCSN - Int64  ]\nColumn Name [EncounterBrownCSN]: CSN\nDeidentification Method:\n   Nothing\n > Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  DiagnosisTerminologyType - CSV.PooledString  ]\nColumn Name [DiagnosisTerminologyType]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  DiagnosisTerminologyValue - CSV.PooledString  ]\nColumn Name [DiagnosisTerminologyValue]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  PatientPrimaryMRN - Int64  ]\nColumn Name [PatientPrimaryMRN]:\nDeidentification Method:\n   Nothing\n > Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  ArrivalDepartmentName - CSV.PooledString  ]\nColumn Name [ArrivalDepartmentName]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\nDataset Name [med]:\n\n[  EncounterBrownCSN - Int64  ]\nColumn Name [EncounterBrownCSN]: CSN\nDeidentification Method:\n   Nothing\n > Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  ArrivalDateandTime - Dates.DateTime  ]\nColumn Name [ArrivalDateandTime]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n > Date Shift\n   Drop\n\n[  MedicationName - CSV.PooledString  ]\nColumn Name [MedicationName]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  MedicationTherapeuticClass - Int64  ]\nColumn Name [MedicationTherapeuticClass]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\nDataset Name [pat]:\n\n[  ArrivalDateandTime - Dates.DateTime  ]\nColumn Name [ArrivalDateandTime]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n > Date Shift\n   Drop\n\n[  ArrivalDepartmentName - CSV.PooledString  ]\nColumn Name [ArrivalDepartmentName]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  DepartureDateandTime - Dates.DateTime  ]\nColumn Name [DepartureDateandTime]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n > Date Shift\n   Drop\n\n[  EncounterBrownCSN - Int64  ]\nColumn Name [EncounterBrownCSN]: CSN\nDeidentification Method:\n   Nothing\n > Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  PatientBirthDate - Dates.DateTime  ]\nColumn Name [PatientBirthDate]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n > Date Shift\n   Drop\n\n[  PatientLastName - String  ]\nColumn Name [PatientLastName]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n > Drop\n\n[  PatientPostalCode - String  ]\nColumn Name [PatientPostalCode]:\nDeidentification Method:\n   Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n > Drop\n\n[  PatientPrimaryMRN - Int64  ]\nColumn Name [PatientPrimaryMRN]:\nDeidentification Method:\n   Nothing\n > Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  PatientSex - CSV.PooledString  ]\nColumn Name [PatientSex]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n[  PatientSSN - String  ]\nColumn Name [PatientSSN]:\nDeidentification Method:\n > Nothing\n   Hash\n   Hash & Salt\n   Date Shift\n   Drop\n\n\nAll set! Writing your config file to test.yaml\nYour file is ready - please review it and add any pre- or post-processing steps as needed.","category":"page"},{"location":"usage/#Build-Configuration-from-a-CSV-1","page":"Guide","title":"Build Configuration from a CSV","text":"","category":"section"},{"location":"usage/#","page":"Guide","title":"Guide","text":"The configuration from a CSV file is designed to work with BCBI's data request worksheet. However, it simply requires a CSV file that contains at least three fields:","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Source Table: The name of the CSV file that will contain the data\nField: The name of the field to map\nMethod: The DeIdentification method which can be any of Hash, Hash & Salt, Hash - Research ID, Date Shift, or Drop. Methods not matching these names will be ignored. Note that a field marked Hash - Research ID will be treated as the primary id for the dataset and needs to have the same name in all data sources.","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"Other fields or method values will be ignored by the tool. It can be run by using the build_config_from_csv function.","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"A valid CSV file designed to be consumed by this tool might look like this:","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":" Source Universe,Source Table,Field,PHI,Method\nBCBI Clinic Visits,BCBI Clinic Detail,Patient Id,Y,Hash - Research ID\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Arrival Method,N,\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Discharge Disposition,N,\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Acuity Level,N,\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Level Of Care,N,\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Financial Class,N,\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Facility Level Of Service,N,\nBCBI Clinic Visits,BCBI Clinic Detail,BCBI Clinic Professional Level Of Service,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Clinic Visit Encounter Csn,Y,Hash\nBCBI Clinic Visits,BCBI Clinic Detail,Clinic Department Name,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Clinic Department Id,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Primary Clinic Diagnosis Name,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Primary Clinic Diagnosis Id,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Primary Chief Complaint Name,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Primary Chief Complaint Id,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter Type,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter Admission Type,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter Admission Source,N,\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter Date,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter End Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter Admission Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,Encounter Discharge Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,First Trauma Start Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,First Trauma End Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,Arrival Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Detail,Departure Instant,Y,Date Shift\n,,,,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Id,Y,Hash - Research ID\nBCBI Clinic Visits,BCBI Clinic Demographics,Clinic Visit Encounter Csn,Y,Hash\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Name,Y,Hash & Salt\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient First Name,Y,Hash & Salt\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Middle Name,Y,Hash & Salt\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Last Name,Y,Hash & Salt\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Sex,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Preferred Language,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Ethnicity,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient First Race,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Second Race,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Third Race,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Fourth Race,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Fifth Race,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Multi Racial?,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Birth Date,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Death Instant,Y,Date Shift\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Death Location,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Status,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Address,Y,Drop\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient City,Y,Drop\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient County,Y,Drop\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient State Or Province,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Country,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Postal Code,Y,Hash\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Sexual Orientation,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Marital Status,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Religion,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Smoking Status,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Highest Level Of Education,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Is Cancer Patient?,N,\nBCBI Clinic Visits,BCBI Clinic Demographics,Patient Restricted?,N,\n,,,,\nBCBI Clinic Visits,BCBI Clinic Providers,Patient Id,Y,Hash - Research ID\nBCBI Clinic Visits,BCBI Clinic Providers,Clinic Visit Encounter Csn,Y,Hash\nBCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Attending Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Attending Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Attending Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Mid Level Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Mid Level Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Mid Level Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Resident Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Resident Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Resident Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,First Nurse Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Longest Nurse Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Last Nurse Assigned Third Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Case Manager Id,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Case Manager Npi,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Case Manager Dea Number,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Case Manager Primary Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Case Manager Second Specialty,N,\nBCBI Clinic Visits,BCBI Clinic Providers,Case Manager Third Specialty,N,\n ```\n\n## Running the Pipeline\n\nTo de-identify a data set, pass the config YAML to the `deidentify` function.\n","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"julia deidentify(\"./config.yml\")","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"This will read in the data, de-identify the data, write a log to file, and write the resulting data set to file.\n\nThe pipeline consists of three main steps:\n* Read the configuration file and process the settings\n* De-identify and write the data set\n* Write the dictionaries with salts, dateshift values, and research IDs to files\n\nThe `deidentify` function runs the three steps:\n","category":"page"},{"location":"usage/#","page":"Guide","title":"Guide","text":"julia projconfig = DeIdConfig(cfgfile) deid = DeIdentified(proj_config) ```","category":"page"},{"location":"#DeIdentification.jl-1","page":"Home","title":"DeIdentification.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"A Julia package for de-identifying CSV data sets containing protected health information.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"pages = [\n    \"Guide\" => \"usage.md\",\n    \"API\" => \"documentation.md\"\n]","category":"page"},{"location":"#Quick-Notes:-1","page":"Home","title":"Quick Notes:","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Compatible with Julia 1.0 and above\nIn your directory make sure to have the following sub-directories:\nlogs\noutput\nAll of the CSVs to be de-identified must contain a common identifier for the unit of analysis (e.g. patient ID)\nA config YAML file is required to run the pipeline","category":"page"},{"location":"documentation/#API-Reference-1","page":"API","title":"API Reference","text":"","category":"section"},{"location":"documentation/#","page":"API","title":"API","text":"Modules = [DeIdentification]","category":"page"},{"location":"documentation/#DeIdentification.DeIdDicts-Tuple{Any,Any}","page":"API","title":"DeIdentification.DeIdDicts","text":"DeIdDicts(maxdays)\n\nStructure containing dictionaries for project level mappings\n\nPrimary ID -> Research ID\nResearch ID -> DateShift number of days\nResearch ID -> Salt value\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.ProjectConfig-Tuple{String}","page":"API","title":"DeIdentification.ProjectConfig","text":"ProjectConfig(config_file::String)\n\nStructure containing configuration information for project level information in the configuration YAML file.  This includes an array containing the FileConfig structures for dataset level information.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.build_config-Tuple{String,String}","page":"API","title":"DeIdentification.build_config","text":"build_config(data_dir::String, config_file::String)\n\nInteractively guides user through writing a configuration YAML file for DeIdentification. The data_dir should contain one of each type of dataset you expect to deidentify (e.g. the data directory ./test/data' contains pat.csv, med.csv, and dx.csv). The config builder reads the headers of each CSV file and iteratively asks about the output name and deidentification type of each column. The results are written to config_file.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.build_config_from_csv-Tuple{String,String}","page":"API","title":"DeIdentification.build_config_from_csv","text":"build_config_from_csv(project_name::String, file::String)\n\nGenerates a configuration YAML file from a CSV file that defines the mappings. The CSV file needs to have at least three named columns, one called Source Table which defines the name of the CSV file the data will be read from, a second called Field which defines the name of the field in the data source and a final column called Method which contains the method to apply (one of Hash - Research ID, Hash, Hash & Salt, Date Shift, or Drop).\n\nAny column renames and pre- or post-processing will need to be added manually to the file.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.deidentify-Tuple{ProjectConfig}","page":"API","title":"DeIdentification.deidentify","text":"deidentify(cfg::ProjectConfig)\n\nThis is the constructor for the DeIdentified struct. We use this type to store arrays of DeIdDataFrame variables, while also keeping a common salt_dict and dateshift_dict between DeIdDataFrames. The salt_dict allows us to track what salt was used on what cleartext. This is only necessary in the case of doing re-identification. The id_dict argument is a dictionary containing the hash digest of the original primary ID to our new research IDs.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.deidentify-Tuple{String}","page":"API","title":"DeIdentification.deidentify","text":"deidentify(config_path)\n\nRun entire pipeline: Processes configuration YAML file, de-identifies the data, and writes the data to disk.  Returns the dictionaries containing the mappings.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.FileConfig","page":"API","title":"DeIdentification.FileConfig","text":"FileConfig(name, filename, colmap, rename_cols)\n\nStructure containing configuration information for each datset in the configuration YAML file.  The colmap contains mapping of column names to their deidentification action (e.g. hash, salt, drop).\n\n\n\n\n\n","category":"type"},{"location":"documentation/#DeIdentification.dateshift_val!-Tuple{DeIdDicts,Union{Missing, Dates.Date, Dates.DateTime},Int64}","page":"API","title":"DeIdentification.dateshift_val!","text":"dateshift_val!(dicts, val, pid)\n\nDateshift fields containing dates. Dates are shifted by a maximum number of days specified in the project config.  All of the dates for the same primary key are shifted the same number of days. Of note is that missing values are left missing.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.deid_file!-Tuple{DeIdDicts,DeIdentification.FileConfig,ProjectConfig,Any}","page":"API","title":"DeIdentification.deid_file!","text":"deid_file!(dicts, file_config, project_config, logger)\n\nReads raw file and deidentifies per file configuration and project configurationg. Writes the deidentified data to a CSV file and updates the global dictionaries tracking identifier mappings.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.getcurrentdate-Tuple{}","page":"API","title":"DeIdentification.getcurrentdate","text":"getcurrentdate()\n\nReturns the current date as a string conforming to ISO8601 basic format.\n\nThis is used to generate filenames in a cross-platform compatible way.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.hash_salt_val!-Tuple{DeIdDicts,Any,Int64}","page":"API","title":"DeIdentification.hash_salt_val!","text":"hash_salt_val!(dicts, val, pid)\n\nSalt and hash fields containing unique identifiers. Hashing is done in place using SHA256 and a 64-bit salt. Of note is that missing values are left missing.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.setrid-Tuple{Any,DeIdDicts}","page":"API","title":"DeIdentification.setrid","text":"setrid(val, dicts)\n\nSet the value passed (a hex string) to a human readable integer.  It generates a new ID if the value hasn't been seen before, otherwise the existing ID is used.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.write_dicts-Tuple{DeIdDicts,Any,Any}","page":"API","title":"DeIdentification.write_dicts","text":"write_dicts(deid_dicts)\n\nWrites DeIdDicts structure to file. The dictionaries are written to josn. The files are written to the  output_path specified in the configuration YAML.\n\n\n\n\n\n","category":"method"},{"location":"documentation/#DeIdentification.write_yaml-Tuple{String,AbstractDict}","page":"API","title":"DeIdentification.write_yaml","text":"write_yaml(file::String, yml::AbstractDict)\n\nRecursively writes YAML object to file. A YAML object is a dictionary, which can contain arrays of YAML objects.  See YAML.jl for more on format.\n\n\n\n\n\n","category":"method"}]
}