process SAMPLESHEET_CHECK {
    tag "$samplesheet"

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-small'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    publishDir = [
                path: { "${params.outdir}/pipeline_info" },
                mode: "${params.publish_dir_mode}",
                saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
            ]

    cpus   = { 2 }
    memory = { 20.GB }
    time   = { 24.h  }

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    script: // This script is bundled with the pipeline, in nf-core/mycosnp/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
