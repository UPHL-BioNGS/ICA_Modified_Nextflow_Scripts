process SEQKIT_REPLACE {
    tag "$meta.id"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    conda (params.enable_conda ? "bioconda::seqkit=2.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0':
        'quay.io/biocontainers/seqkit:2.1.0--h9ee0642_0' }"

    ext.args            = { "-s -p '\\*' -r '-'" }
    ext.suffix          = { "fasta" }
    ext.errorStrategy   = { "ignore" }
    ext.prefix          = { "vcf-to-fasta" }
    ext.when            = {  }
    publishDir          = [
                enabled: true,
                mode: "${params.publish_dir_mode}",
                path: { "${params.outdir}/combined/vcf-to-fasta" },
                pattern: "vcf-to-fasta.fasta"
            ]

    input:
    tuple val(meta), path(fastx)

    output:
    tuple val(meta), path("*.fast*"), emit: fastx
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = "fastq"
    if ("$fastx" ==~ /.+\.fasta|.+\.fasta.gz|.+\.fa|.+\.fa.gz|.+\.fas|.+\.fas.gz|.+\.fna|.+\.fna.gz/) {
        extension = "fasta"
    }
    def endswith = task.ext.suffix ?: "${extension}.gz"
    """
    seqkit \\
        replace \\
        ${args} \\
        --threads ${task.cpus} \\
        -i ${fastx} \\
        -o ${prefix}.${endswith}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit | sed '3!d; s/Version: //' )
    END_VERSIONS
    """
}
