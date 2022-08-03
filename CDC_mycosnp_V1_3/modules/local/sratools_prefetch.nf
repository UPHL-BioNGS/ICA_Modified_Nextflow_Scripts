process SRATOOLS_PREFETCH {
    tag "$id"
    label 'process_low'
    label 'error_retry'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    conda (params.enable_conda ? 'bioconda::sra-tools=2.11.0' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sra-tools:2.11.0--pl5262h314213e_0' :
        'quay.io/biocontainers/sra-tools:2.11.0--pl5262h314213e_0' }"


    publishDir = [
               path: { "${params.outdir}/sra" },
               enabled: false
           ]

    cpus   = { 3 }
    memory = { 14.GB }

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    input:
    tuple val(meta), val(id)

    output:
    tuple val(meta), path("$id"), emit: sra
    path "versions.yml"         , emit: versions

    script:
    def args = task.ext.args ?: ''
    def config = "/LIBS/GUID = \"${UUID.randomUUID().toString()}\"\\n/libs/cloud/report_instance_identity = \"true\"\\n"
    """
    eval "\$(vdb-config -o n NCBI_SETTINGS | sed 's/[" ]//g')"
    if [[ ! -f "\${NCBI_SETTINGS}" ]]; then
        mkdir -p "\$(dirname "\${NCBI_SETTINGS}")"
        printf '${config}' > "\${NCBI_SETTINGS}"
    fi
    retry_with_backoff.sh prefetch \\
        $args \\
        --progress \\
        $id
    vdb-validate $id
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sratools: \$(prefetch --version 2>&1 | grep -Eo '[0-9.]+')
    END_VERSIONS
    """
}
// taken from [nf-core/fetchngs](https://github.com/nf-core/fetchngs/blob/master/modules/local/sratools_prefetch.nf)
