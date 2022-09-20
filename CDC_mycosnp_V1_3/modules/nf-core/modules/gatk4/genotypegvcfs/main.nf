process GATK4_GENOTYPEGVCFS {
    tag "$meta.id"
    label 'process_medium'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    conda (params.enable_conda ? "bioconda::gatk4=4.2.4.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.4.1--hdfd78af_0' :
        'quay.io/biocontainers/gatk4:4.2.4.1--hdfd78af_0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    ext.args         = { "" }
    ext.when         = {  }
    ext.prefix        = {"combined_genotype"}
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/genotypegvcfs" },
            pattern: "*{vcf.gz,vcf.gz.tbi}"
        ]

    input:
    tuple val(meta), path(gvcf), path(gvcf_index), path(intervals)
    path  fasta
    path  fasta_index
    path  fasta_dict
    path  dbsnp
    path  dbsnp_index

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    tuple val(meta), path("*.tbi")   , emit: tbi
    path  "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def dbsnp_options    = dbsnp ? "-D ${dbsnp}" : ""
    def interval_options = intervals ? "-L ${intervals}" : ""
    def gvcf_options     = gvcf.name.endsWith(".vcf") || gvcf.name.endsWith(".vcf.gz") ? "$gvcf" : "gendb://$gvcf"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK GenotypeGVCFs] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    gatk --java-options "-Xmx${avail_mem}g" \\
        GenotypeGVCFs \\
        $args \\
        $interval_options \\
        $dbsnp_options \\
        -R $fasta \\
        -V $gvcf_options \\
        -O ${prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
