process PICARD_MARKDUPLICATES {
    tag "$meta.id"
    label 'process_medium'

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'

    conda (params.enable_conda ? "bioconda::picard=2.26.10" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:2.26.10--hdfd78af_0' :
        'quay.io/biocontainers/picard:2.26.10--hdfd78af_0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 6 }
    memory = { 28.GB }

    ext.args         = { "REMOVE_DUPLICATES=true ASSUME_SORT_ORDER=coordinate VALIDATION_STRINGENCY=LENIENT" }
        //ext.args         = { "-REMOVE_DUPLICATES \"true\" -ASSUME_SORT_ORDER \"coordinate\" -VALIDATION_STRINGENCY \"LENIENT\" " }
    ext.prefix         = { "${meta.id}_markdups"}
    ext.when         = {  }
    publishDir       = [
            enabled: "${params.save_debug}",
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/samples/${meta.id}/picard_markduplicates" },
            pattern: "*.bam"
        ]

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam")        , emit: bam
    tuple val(meta), path("*.bai")        , optional:true, emit: bai
    tuple val(meta), path("*.metrics.txt"), emit: metrics
    path  "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard MarkDuplicates] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    picard \\
        -Xmx${avail_mem}g \\
        MarkDuplicates \\
        $args \\
        I=$bam \\
        O=${prefix}.bam \\
        M=${prefix}.MarkDuplicates.metrics.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard MarkDuplicates --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
