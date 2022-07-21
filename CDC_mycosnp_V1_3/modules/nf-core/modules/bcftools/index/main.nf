process BCFTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    conda (params.enable_conda ? 'bioconda::bcftools=1.14' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.14--h88f3f91_0' :
        'quay.io/biocontainers/bcftools:1.14--h88f3f91_0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 4 }
    memory = { 20.GB }
    time   = { 24.h  }

    ext.args         = {  }
    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/selectedsnpsfiltered" },
            pattern: "*{csi,tbi}"
        ]

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.csi"), optional:true, emit: csi
    tuple val(meta), path("*.tbi"), optional:true, emit: tbi
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    bcftools \\
        index \\
        $args \\
        --threads $task.cpus \\
        $vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}