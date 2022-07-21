process BWA_INDEX {
    tag "$fasta"
    label 'process_high'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'

    conda (params.enable_conda ? "bioconda::bwa=0.7.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bwa:0.7.17--hed695b0_7' :
        'quay.io/biocontainers/bwa:0.7.17--hed695b0_7' }"

    ext.args         = { "" }
    ext.when         = {  }
    publishDir       = [
                enabled: "${params.save_reference}",
                mode: "${params.publish_dir_mode}",
                path: { "${params.outdir}/reference/bwa" },
                pattern: "bwa"
            ]

    cpus   = { 8 }
    memory = { 64.GB }
    time   = { 24.h  }

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    input:
    path fasta

    output:
    path "bwa"         , emit: index
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir bwa
    bwa \\
        index \\
        $args \\
        -p bwa/${fasta.baseName} \\
        $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(echo \$(bwa 2>&1) | sed 's/^.*Version: //; s/Contact:.*\$//')
    END_VERSIONS
    """
}
