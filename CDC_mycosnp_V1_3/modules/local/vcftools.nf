process FILTER_GATK_GENOTYPES {
    tag "$meta.id"
    label 'process_low'

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    conda (params.enable_conda ? "bioconda::scipy=1.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/scipy%3A1.1.0' :
        'quay.io/biocontainers/scipy:1.1.0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries    = 1
    maxErrors     = '-1'

    cpus   = { 3 }
    memory = { 14.GB }

    ext.args         = { params.gatkgenotypes_filter }
    ext.when         = {  }
    ext.prefix        = {"combined_genotype_filtered_snps_filtered"}
    publishDir       = [
             enabled: "${params.save_debug}",
             mode: "${params.publish_dir_mode}",
             path: { "${params.outdir}/combined/selectedsnpsfiltered" },
             pattern: "*{vcf.gz,vcf.gz.tbi}"
         ]

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    // path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def is_compressed_vcf = vcf.getName().endsWith(".gz") ? true : false
    def vcf_name = vcf.getName().replace(".gz", "")

    """
    if [ "$is_compressed_vcf" == "true" ]; then
        gzip -c -d $vcf > $vcf_name
    fi

    python $projectDir/bin/broad-vcf-filter/filterGatkGenotypes.py  $vcf_name \\
                            $args \\
                           > ${prefix}.vcf
    gzip ${prefix}.vcf
    """

}
