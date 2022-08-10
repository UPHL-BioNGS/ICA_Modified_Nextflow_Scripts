process BEDTOOLS_MASKFASTA {
    tag "$meta.id"
    label 'process_medium'

    maxForks 5

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'

    conda (params.enable_conda ? "bioconda::bedtools=2.30.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.30.0--hc088bd4_0' :
        'quay.io/biocontainers/bedtools:2.30.0--hc088bd4_0' }"

    ext.args         = { "" }
    ext.when         = {  }
    publishDir = [
                path: { "${params.outdir}/reference/masked" },
                mode: "${params.publish_dir_mode}",
                pattern: "*.fa"
            ]

    cpus   = { 6 }
    memory = { 28.GB }

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    input:
    tuple val(meta), path(bed)
    path  fasta

    output:
    tuple val(meta), path("*.fa"), emit: fasta
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bedtools \\
        maskfasta \\
        $args \\
        -fi $fasta \\
        -bed $bed \\
        -fo ${prefix}.fa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """
}
