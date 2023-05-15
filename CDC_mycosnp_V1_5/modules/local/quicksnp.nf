process QUICKSNP {
    tag "$meta.id"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            saveAs: { filename -> if( filename.endsWith(".nwk")) { return "quicksnp_phylogeny.nwk" } else { return filename }  },
            path: { "${params.outdir}/combined/phylogeny/quicksnp" },
            pattern: "*"
        ]

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    // conda (params.enable_conda ? "bioconda::quicksnp=1.0.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/staphb/quicksnp:1.0.1' :
        'quay.io/staphb/quicksnp:1.0.1' }"

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("*.nwk"), emit: quicksnp_tree
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    QuickSNP.py \\
        --dm ${tsv} \\
        --outtree quicksnp_tree.nwk
    """
}