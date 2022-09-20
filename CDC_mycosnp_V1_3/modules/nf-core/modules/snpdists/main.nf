process SNPDISTS {
    tag "$meta.id"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    conda (params.enable_conda ? "bioconda::snp-dists=0.8.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snp-dists:0.8.2--h5bf99c6_0' :
        'quay.io/biocontainers/snp-dists:0.8.2--h5bf99c6_0' }"

    ext.args            = { "" }
    ext.errorStrategy   = { "ignore" }
    ext.when            = {  }
    publishDir          = [
                enabled: true,
                mode: "${params.publish_dir_mode}",
                path: { "${params.outdir}/combined/snpdists" },
                pattern: "*.tsv"
            ]


    input:
    tuple val(meta), path(alignment)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    snp-dists \\
        $args \\
        $alignment > ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpdists: \$(snp-dists -v 2>&1 | sed 's/snp-dists //;')
    END_VERSIONS
    """
}
