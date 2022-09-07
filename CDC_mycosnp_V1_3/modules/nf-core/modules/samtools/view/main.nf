process SAMTOOLS_VIEW {
    tag "$meta.id"
    label 'process_medium'

<<<<<<< HEAD
    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10
=======
    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
>>>>>>> parent of 1d23bed (Updating the files that have been modified with maxFork statements)

    conda (params.enable_conda ? "bioconda::samtools=1.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.14--hb421002_0' :
        'quay.io/biocontainers/samtools:1.14--hb421002_0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'


    ext.args         = { "" }
    ext.when         = {  }
    publishDir       = [
           enabled: "${params.save_alignment}",
           mode: "${params.publish_dir_mode}",
           path: { "${params.outdir}/samples/${meta.id}/finalbam" },
           pattern: "*.bai"
       ]

    input:
    tuple val(meta), path(input)
    path fasta

    output:
    tuple val(meta), path("*.bam") , emit: bam , optional: true
    tuple val(meta), path("*.cram"), emit: cram, optional: true
    path  "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reference = fasta ? "--reference ${fasta} -C" : ""
    def file_type = input.getExtension()
    if ("$input" == "${prefix}.${file_type}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    samtools \\
        view \\
        --threads ${task.cpus-1} \\
        ${reference} \\
        $args \\
        $input \\
        $args2 \\
        > ${prefix}.${file_type}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
