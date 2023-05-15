process SAMPLESHEET_MERGE {
    tag "$samplesheet"

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    conda (params.enable_conda ? "conda-forge::perl=5.22.2.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.22.2.1' :
        'quay.io/biocontainers/perl:5.22.2.1' }"

    input:
    path(samplesheet)

    output:
    path 'samplesheet.system.csv'  , emit: csv

    script: // This script is bundled with the pipeline, in nf-core/mycosnp/bin/
    """
    pearl $projectDir/bin/mycosnp_combine_lanes.pl -i $samplesheet > samplesheet.system.csv

    # TODO: Add version
    
    """
}
