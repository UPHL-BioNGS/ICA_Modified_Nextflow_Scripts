# ICA_Modified_Nextflow_Scripts
To be able to run Nextflow scripts that are published on Github on ICA they must be modified.
ICA does not allow Nextflow to do a gitpull like ```nextflow run UPHL-BioNGS/Grandeur -profile singularity -r main``` and an ICA user cannot pass config or param files.
These scripts are how UPHL has gotten around those limitations to run analyses on ICA.
Mainly by editing subworkflows and modules manually that the config and parm files do programatically. 
Each folder in this repository represents a pipeline that works on ICA.
main.nf and the xml_configuration are saved on ICA when pipelines are created; each of these files are located in each pipelines directory in this repository but they do not need to be uploaded ICA.
I will also include a file with the SRA ids as example samples each pipeline runs and around the usual number that UPHLs runs at a time.
You can use the SRA toolkit's FASTQDump to get these samples.

Some pipelines have python scripts that help UPHL initiate runs; I will also included those in the pipelines directory but they are not needed for runs to work on ICA. 

I would also like to point out a useful tool that Ken Eng [@keng404](https://github.com/keng404) of Illumina developed that is a good starting point for developing Nextflow pipelines for ICA. https://github.com/keng404/nextflow-to-icav2 I use it to help find all the params hidden within a Nextflow pipeline.
