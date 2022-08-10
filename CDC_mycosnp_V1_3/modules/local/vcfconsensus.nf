process VCF_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    maxForks 5

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'

    conda (params.enable_conda ? 'bioconda::bcftools=1.14' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.14--h88f3f91_0' :
        'quay.io/biocontainers/bcftools:1.14--h88f3f91_0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 6 }
    memory = { 28.GB }

    ext.when         = {  }
    publishDir       = [
            enabled: "${params.save_debug}",
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/consensus" },
            pattern: "*{fasta.gz}"
        ]

    input:
    tuple val(meta), path(vcf), path(tbi)
    path(fasta)

    output:
    tuple val(meta), path("*.fasta.gz"), emit: fastas
    tuple val(meta), path("*.txt"), emit: txt
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # First get a list of samples
    bcftools query \\
        -l \\
        $vcf > samplelist.txt
    for SAMPLE in \$(cat samplelist.txt); do
        echo ">\$SAMPLE" > \${SAMPLE}.fasta
        bcftools consensus -s \$SAMPLE -f $fasta $vcf |  grep -E -v "^>" | grep -E -v "^\$" >> \${SAMPLE}.fasta
        gzip \${SAMPLE}.fasta
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
