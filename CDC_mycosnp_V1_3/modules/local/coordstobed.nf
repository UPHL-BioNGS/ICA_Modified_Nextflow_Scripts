process COORDSTOBED {
    tag "$meta.id"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

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

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

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
