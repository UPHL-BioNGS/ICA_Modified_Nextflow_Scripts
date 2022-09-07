process QUALIMAP_BAMQC {
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

    conda (params.enable_conda ? "bioconda::qualimap=2.2.2d" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/qualimap:2.2.2d--1' :
        'quay.io/biocontainers/qualimap:2.2.2d--1' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    ext.args         = { "" }
    ext.when         = {  }
    ext.prefix       = { "${meta.id}"}
    publishDir       = [
            enabled: "${params.save_alignment}",
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/stats/qualimap" },
            pattern: "*"
        ]

    input:
    tuple val(meta), path(bam)
    path gff
    val use_gff

    output:
    tuple val(meta), path("${prefix}"), emit: results
    path  "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"

    def collect_pairs = meta.single_end ? '' : '--collect-overlap-pairs'
    def memory     = task.memory.toGiga() + "G"
    def regions = use_gff ? "--gff $gff" : ''

    def strandedness = 'non-strand-specific'
    if (meta.strandedness == 'forward') {
        strandedness = 'strand-specific-forward'
    } else if (meta.strandedness == 'reverse') {
        strandedness = 'strand-specific-reverse'
    }
    """
    unset DISPLAY
    mkdir tmp
    export _JAVA_OPTIONS=-Djava.io.tmpdir=./tmp
    qualimap \\
        --java-mem-size=$memory \\
        bamqc \\
        $args \\
        -bam $bam \\
        $regions \\
        -p $strandedness \\
        $collect_pairs \\
        -outdir $prefix \\
        -nt $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qualimap: \$(echo \$(qualimap 2>&1) | sed 's/^.*QualiMap v.//; s/Built.*\$//')
    END_VERSIONS
    """
}
