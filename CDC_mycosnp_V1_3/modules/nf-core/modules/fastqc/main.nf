process FASTQC {
    tag "$meta.id"
    label 'process_medium'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    conda (params.enable_conda ? "bioconda::fastqc=0.11.9" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastqc:0.11.9--0' :
        'quay.io/biocontainers/fastqc:0.11.9--0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    ext.args         = '--quiet'
    ext.when         = {  }
    ext.prefix       = { "${meta.id}" }
    publishDir       = [
            enabled: "${params.save_alignment}",
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/samples/${meta.id}/fastqc_post" },
            pattern: "*",
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path  "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    // Add soft-links to original FastQs for consistent naming in pipeline
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (meta.single_end) {
        """
        [ ! -f  ${prefix}.fastq.gz ] && ln -s $reads ${prefix}.fastq.gz
        fastqc $args --threads $task.cpus ${prefix}.fastq.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastqc: \$( fastqc --version | sed -e "s/FastQC v//g" )
        END_VERSIONS
        """
    } else {
        """
        [ ! -f  ${prefix}_1.fastq.gz ] && ln -s ${reads[0]} ${prefix}_1.fastq.gz
        [ ! -f  ${prefix}_2.fastq.gz ] && ln -s ${reads[1]} ${prefix}_2.fastq.gz
        fastqc $args --threads $task.cpus ${prefix}_1.fastq.gz ${prefix}_2.fastq.gz

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastqc: \$( fastqc --version | sed -e "s/FastQC v//g" )
        END_VERSIONS
        """
    }
}
