process COORDSTOBED {
    tag "$meta.id"
    label 'process_low'

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    conda (params.enable_conda ? "bioconda::mummer=3.23" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mummer:3.23--pl5262h1b792b2_12' :
        'quay.io/biocontainers/mummer:3.23--pl5262h1b792b2_12' }"

    publishDir = [
                enabled: "${params.save_debug}",
                path: { "${params.outdir}/reference/masked" },
                mode: "${params.publish_dir_mode}",
                pattern: "*.bed"
            ]

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 3 }
    memory = { 14.GB }


    input:
    tuple val(meta), path(delta)

    output:
    tuple val(meta), path("masked_ref.bed"), emit: bed
    // path "versions.yml", emit: versions

    script:
    """
    show-coords -r -T -H $delta > masked_ref_BEFORE_ORDER.bed
    awk '{if (\$1 != \$3 && \$2 != \$4) print \$0}' masked_ref_BEFORE_ORDER.bed > masked_ref_BEFORE_ORDER2.bed
    awk '{print \$8\"\\t\"\$1\"\\t\"\$2}' masked_ref_BEFORE_ORDER2.bed > masked_ref.bed
    """
}
