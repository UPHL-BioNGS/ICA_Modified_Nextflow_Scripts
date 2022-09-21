process RAXMLNG {
    label 'process_high'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    conda (params.enable_conda ? 'bioconda::raxml-ng=1.0.3' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/raxml-ng:1.0.3--h32fcf60_0' :
        'quay.io/biocontainers/raxml-ng:1.0.3--h32fcf60_0' }"

    ext.args         = { "--all --model GTR+G --bs-trees 1000" }
    ext.errorStrategy = { "ignore" }
    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            saveAs: { filename -> if( filename.endsWith(".bestTree")) { return "raxmlng_bestTree.nh" } else if ( filename.endsWith(".support") ) { return "raxmlng_support.nh" } else { return filename }  },
            path: { "${params.outdir}/combined/phylogeny/raxmlng" },
            pattern: "*"
        ]

    input:
    path alignment

    output:
    path "*.raxml.bestTree", emit: phylogeny
    path "*.raxml.support" , optional:true, emit: phylogeny_bootstrapped
    path "versions.yml"    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    raxml-ng \\
        $args \\
        --msa $alignment \\
        --threads $task.cpus \\
        --prefix output

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        raxmlng: \$(echo \$(raxml-ng --version 2>&1) | sed 's/^.*RAxML-NG v. //; s/released.*\$//')
    END_VERSIONS
    """
}
