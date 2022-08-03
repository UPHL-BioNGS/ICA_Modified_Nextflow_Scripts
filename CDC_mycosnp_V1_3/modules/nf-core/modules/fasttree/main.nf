process FASTTREE {
    label 'process_medium'

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'

    conda (params.enable_conda ? "bioconda::fasttree=2.1.10" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fasttree:2.1.10--h516909a_4' :
        'quay.io/biocontainers/fasttree:2.1.10--h516909a_4' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 6 }
    memory = { 28.GB }


    ext.args         = { "-gtr -gamma -fastest" }
    ext.errorStrategy = { "ignore" }
    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            saveAs: { filename -> filename.endsWith(".tre") ? "fasttree_phylogeny.nh" : filename  },
            path: { "${params.outdir}/combined/phylogeny/fasttree" },
            pattern: "*"
        ]

    input:
    path alignment

    output:
    path "*.tre",         emit: phylogeny
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    fasttree \\
        $args \\
        -log fasttree_phylogeny.tre.log \\
        -nt $alignment \\
        > fasttree_phylogeny.tre

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fasttree: \$(fasttree -help 2>&1 | head -1  | sed 's/^FastTree \\([0-9\\.]*\\) .*\$/\\1/')
    END_VERSIONS
    """
}
