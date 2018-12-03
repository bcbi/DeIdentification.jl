# Usage Guide

## DeIdentification Methods

Data can be processed in several different ways depending on the desired output
* Dropped: drop the column as it is not needed for analysis or as identifier
* Hashed: obfuscate the data in the column, but maintain referential integrity for joining data
* Hashed and Salted: obfuscate the data in the column, but do not maintain referential integrity for joining data (useful for columns that would only be needed in re-identifying data)
* Date Shifted: Shift date or datetime columns by a random value (all date/times related to the primary identifier will be shifted by the same random number)
* Nothing: columns are not identifying data and do not need to be obfuscated

## Config YAML
To indicate how to de-identify the data, where the data lives, and other variables a
configuration YAML file must be created by the user.

```
# config.yml
project:                <project name> # required
project_seed:           <int>          # optional, but required for reproducibility
log_path:               <dir path>     # required, must already be created
max_dateshift_days:     <int>          # optional, default is 30
output_path:            <dir path>     # required, must already be created

# The primary ID must be present in all data sets, so that date shifting and salting work appropriately
primary_id: <column name>       # required

# 1 to n datasets must be present to de-identify
datasets:
  - name: <dataset name 1>          # required, used to name output file
    filename: <file path>         # required, path for input CSV
    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing
      - in: <col name 1a>                # required, current column name
        out: <col name 1b>               # required, future column name
    hash_cols:                    # optional, columns to be hashed
      - <col name 1>
      - <col name 2>
    dateshift_cols:               # optional, columns to be dateshifted
      - <col name 1>
      - <col name 2>
    salt_cols:                    # optional, columns to be hashed and salted
      - <col name 1>
      - <col name 2>
    drop_cols:                    # optional, columns to be excluded from the de-identified data set
      - <col name 1>
      - <col name 2>
  - name: <dataset name 2>          # required, used to name output file
    filename: <file path>         # required, path for input CSV
    rename_cols:                  # optional, useful if columns used in joining have different names, renaming occurs before any other processing
      - in: <col name 1a>                # required, current column name
        out: <col name 1b>               # required, future column name
    hash_cols:                    # optional, columns to be hashed
      - <col name 1>
      - <col name 2>
    dateshift_cols:               # optional, columns to be dateshifted
      - <col name 1>
      - <col name 2>
    salt_cols:                    # optional, columns to be hashed and salted
      - <col name 1>
      - <col name 2>
    drop_cols:                    # optional, columns to be excluded from the de-identified data set
      - <col name 1>
      - <col name 2>
```

### Example Config

```YAML
project:                "ehr"
project_seed:           42          # for reproducibility
log_path:               "./logs"
max_dateshift_days:     30
output_path:            "./output"

# The primary ID must be present in all data sets, so that dateshifting and salting works appropriately
primary_id: "CSN"

datasets:
  - name: dx
    filename: "./data/dx.csv"
    rename_cols:
      - in: "EncounterEpicCSN"
        out: "CSN"
    hash_cols:
      - "CSN"
      - "PatientPrimaryMRN"
    dateshift_cols:
      - "ArrivalDateandTime"
  - name: pat
    filename: "./data/pat.csv"
    # NOTE: renaming happens before any other operations (hashing, salting, dropping, dateshifting)
    rename_cols:
      - in: "EncounterEpicCSN"
        out: "CSN"
      - in: "PatientLastName"
        out: "last_name"
    hash_cols:
      - "CSN"
      - "PatientPostalCode"
    salt_cols:
      - "last_name"
    dateshift_cols:
      - "ArrivalDateandTime"
      - "DepartureDateandTime"
      - "PatientBirthDate"
  - name: med
    filename: "./data/med.csv"
    rename_cols:
      - in: "EncounterEpicCSN"
        out: "CSN"
    hash_cols:
      - "CSN"
    dateshift_cols:
      - "ArrivalDateandTime"
    drop_cols:
      - "MedicationTherapeuticClass"
```
## Running the Pipeline

To de-identify a data set, pass the config YAML to the `deidentify` function.

```julia
deidentify("./config.yml")
```
This will read in the data, de-identify the data, write a log to file, and write the resulting data set to file.

The pipeline consists of three main steps:
* Read the configuration file and process the settings
* De-identify the data set
* Write the de-identified data to files

The `deidentify` function runs the three steps:

```julia
proj_config = DeIdConfig(cfg_file)
deid = DeIdentified(proj_config)
DeIdentification.write(deid)
```
