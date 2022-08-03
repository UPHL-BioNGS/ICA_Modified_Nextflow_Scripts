process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_low'

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    conda (params.enable_conda ? "bioconda::samtools=1.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.14--hb421002_0' :
        'quay.io/biocontainers/samtools:1.14--hb421002_0' }"

    ext.args         = { "" }
    ext.when         = { }
    publishDir       = [
                enabled: "${params.save_reference}",
                mode: "${params.publish_dir_mode}",
                path: { "${params.outdir}/reference/fai" },
                pattern: "*fai"
            ]

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 3 }
    memory = { 14.GB }

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path ("*.fai"), emit: fai
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    samtools \\
        faidx \\
        $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
