# UPHL-BioNGS_Donut_falls

Source Git Repository: https://github.com/UPHL-BioNGS/Donut_Falls

Github Version: 0.0.20220810

By: [@erinyoung](https://github.com/erinyoung)

In order for this pipeline to run successfully you must provide the following files which are labeled with their associated fields in the XML:

## READS
A directory containing nanopore sequencing reads. From the source repository:

Combine all fastq or fastq files into one file per barcode and rename file
Example with fastq.gz for barcode 01 ```cat fastq_pass/barcode01/*fastq.gz > reads/sample.fastq.gz```

## ILLUMINA
A directory containing Illumina paired-end reads. From the source repository:

Illumina reads need to match the same naming convention as the nanopore reads (i.e. `12345.fastq.gz` for nanopore and `12345_R1.fastq.gz` and `12345_R2.fastq.gz` for Illumina)

## SEQUENCING_SUMMARY
This is an optional input. From nanopore instrument, for assessing the quality of a sequencing run using nanoplot

## PROJECT_DIRS FROM EDITED GIT REPO
The directories found in this Github directory:
```
configs
data
modules
subworkflows
```

## SCHEMA_JSON
This file is found in this Github directory ```nextflow_schema.json```
