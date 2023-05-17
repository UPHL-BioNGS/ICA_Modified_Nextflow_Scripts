process GATK4_COMBINEGVCFS {
    tag "$meta.id"
    label 'process_medium'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    conda (params.enable_conda ? "bioconda::gatk4=4.2.5.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.5.0--hdfd78af_0' :
        'quay.io/biocontainers/gatk4:4.2.5.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(vcf), path(vcf_idx)
    path (fasta)
    path (fasta_fai)
    path (fasta_dict)

    output:
    tuple val(meta), path("*.combined.g.vcf.gz"), emit: combined_gvcf
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem       = 3
    if (!task.memory) {
        log.info '[GATK COMBINEGVCFS] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.toGiga()
    }
    def input_files = vcf.collect{"-V ${it}"}.join(' ') // add '-V' to each vcf file
    """
    gatk \\
        --java-options "-Xms${avail_mem} -Xmx${avail_mem}G" \\
        CombineGVCFs \\
        -R ${fasta} \\
        -O ${prefix}.combined.g.vcf.gz \\
        ${args} \\
        ${input_files}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}