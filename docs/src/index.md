# DeIdentification.jl

A Julia package for de-identifying CSV data sets.

```@contents
pages = [
    "Guide" => "usage.md",
    "API" => "documentation.md"
    ]
```

### Quick Notes:
* Compatible with julia 0.7 and above
* In your directory make sure to have the following sub-directories:
  * logs
  * output
* All of the CSVs to be de-identified must contain a common identifier for the unit of analysis (e.g. patient ID)
* A config YAML file is required to run the pipeline
