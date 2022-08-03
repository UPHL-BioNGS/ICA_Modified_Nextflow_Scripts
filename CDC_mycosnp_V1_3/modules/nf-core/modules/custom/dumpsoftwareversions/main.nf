process CUSTOM_DUMPSOFTWAREVERSIONS {
    label 'process_low'

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    // Requires `pyyaml` which does not have a dedicated container but is in the MultiQC container
    conda (params.enable_conda ? "bioconda::multiqc=1.11" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.11--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.11--pyhdfd78af_0' }"

    cpus   = { 3 }
    memory = { 14.GB }

    publishDir = [
            path: { "${params.outdir}/pipeline_info" },
            mode: 'copy',
            pattern: '*_versions.yml'
        ]

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    input:
    path versions

    output:
    path "software_versions.yml"    , emit: yml
    path "software_versions_mqc.yml", emit: mqc_yml
    path "versions.yml"             , emit: versions

    script:
    def args = task.ext.args ?: ''
    template 'dumpsoftwareversions.py'
}
