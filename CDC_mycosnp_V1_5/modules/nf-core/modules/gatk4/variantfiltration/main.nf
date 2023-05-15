process GATK4_VARIANTFILTRATION {
    tag "$meta.id"
    label 'process_medium'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    ext.args         = { "--filter-expression '${params.gvcfs_filter}' --filter-name filter" }
        ext.when         = {  }
        ext.prefix        = {"combined_genotype_filtered"}
        publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/filteredgvcfs" },
            pattern: "*{vcf.gz,vcf.gz.tbi}"
        ]

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    conda (params.enable_conda ? "bioconda::gatk4=4.2.5.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.5.0--hdfd78af_0' :
        'quay.io/biocontainers/gatk4:4.2.5.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(vcf), path(vcf_tbi)
    path  fasta
    path  fai
    path  dict

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    tuple val(meta), path("*.tbi")   , emit: tbi
    path "versions.yml"		         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK VariantFiltration] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.toGiga()
    }
    """
    gatk --java-options "-Xmx${avail_mem}G" VariantFiltration \\
        -R $fasta \\
        -V $vcf \\
        -O ${prefix}.vcf.gz \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
