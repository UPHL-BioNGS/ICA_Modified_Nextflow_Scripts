process IQTREE {
    tag "$alignment"
    label 'process_medium'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}
    
    ext.args         = { "-alrt 1000 -B 1000 -m MFP -czb" }
    ext.errorStrategy = { "ignore" }
    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            saveAs: { filename -> filename.endsWith(".treefile") ? "iqtree_phylogeny.nh" : filename  },
            path: { "${params.outdir}/combined/phylogeny/iqtree" },
            pattern: "*"
        ]

    conda (params.enable_conda ? 'bioconda::iqtree=2.1.4_beta' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:2.1.4_beta--hdcc8f71_0' :
        'quay.io/biocontainers/iqtree:2.1.4_beta--hdcc8f71_0' }"

    input:
    path alignment
    val constant_sites

    output:
    path "*.treefile",    emit: phylogeny
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def fconst_args = constant_sites ? "-fconst $constant_sites" : ''
    def memory      = task.memory.toString().replaceAll(' ', '')
    """
    iqtree \\
        $fconst_args \\
        $args \\
        -s $alignment \\
        -nt AUTO \\
        -ntmax $task.cpus \\
        -mem $memory \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """
}
