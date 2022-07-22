# CDC_mycosnp_V1_3
Source Git Repository: https://github.com/CDCgov/mycosnp-nf

By: Michael Cipriano @mjcipriano Sateesh Peri @sateeshperi Hunter Seabolt @hseabolt Chris Sandlin @cssandlin Drewry Morris @drewry Lynn Dotrang @leuthrasp Christopher Jossart @cjjossart Robert A. Petit III @rpetit3

In order for this pipeline to run successfully you must provide the following files which are labeled with there association fields in the XML:

## INPUT_SAMPLES
These need to be the fastq files only; directories or directories with subdirectories that contain the fastq files will not work.

## INPUT_CSV
mycosnp requires a samplesheet that follows this header and an example of the first row:
``` 
sample_id,fastq_1,fastq_2
123456789,123456789_R1.fastq.gz,123456789_R2.fastq.gz
```
The columns fastq_1 and fastq_2 are suppose to be file paths. When you input samples during the INPUT_SAMPLES step they will be uploading for the analysis in a folder ../data like this:
```/ces/scheduler/run/d6b3eb86-4fbd-49a3-9856-afa38ef7d250/data/``` This data folder is the launch dir for the Nextflow run and just the file name will work for the samplesheet

## MODULES_JSON
This file is found in this Github directory ```modules.json```

## SCHEMA_JSON
This file is found in this Github directory ```nextflow_schema.json```

## PROJECT_DIRS
The directories found in this Github directory:
```
assets
bin
conf 
lib
modules
subworkflows
tmp
workflows
```
## FASTA
This workflow needs a reference fasta to run. ```B11205_reference.fasta``` is the file we have been using and can be found in this Github directory.

## VCFS
You do not need to include any files for this input. mycosnp can be used to for phylogenetic analysis by just inputting VCFs but this is not the regular use for UPHL.






