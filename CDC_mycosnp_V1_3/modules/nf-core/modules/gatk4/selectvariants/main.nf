process GATK4_SELECTVARIANTS {
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

    conda (params.enable_conda ? "bioconda::gatk4=4.2.5.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.5.0--hdfd78af_0':
        'quay.io/biocontainers/gatk4:4.2.5.0--hdfd78af_0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    ext.args         = { '--select-type-to-include "SNP"' }
    ext.when         = {  }
    ext.prefix        = {"combined_genotype_filtered_snps"}
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/selectedsnps" },
            pattern: "*{vcf.gz,vcf.gz.tbi}"
        ]

    input:
    tuple val(meta), path(vcf), path(vcf_idx)

    output:
    tuple val(meta), path("*.selectvariants.vcf.gz")       , emit: vcf
    tuple val(meta), path("*.selectvariants.vcf.gz.tbi")   , emit: tbi
    path "versions.yml"		                               , emit: versions

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
    gatk --java-options "-Xmx${avail_mem}G" SelectVariants \\
        -V $vcf \\
        -O ${prefix}.selectvariants.vcf.gz \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
