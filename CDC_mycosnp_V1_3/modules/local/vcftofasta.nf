process VCF_TO_FASTA {
    tag "${meta.id}"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    conda (params.enable_conda ? "bioconda::scipy=1.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/scipy%3A1.1.0' :
        'quay.io/biocontainers/scipy:1.1.0' }"

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    ext.when         = {  }
    publishDir       = [
            enabled: false,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/vcf-to-fasta" },
            pattern: "*{fasta}"
        ]

    input:
    tuple val(meta), path(vcf), path(samplelist), val(max_amb_samples), val(max_perc_amb_samples), val(min_depth)
    path(fasta)

    output:
    tuple val(meta), path("*.fasta"), emit: fasta
    // path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def is_compressed_vcf = vcf.getName().endsWith(".gz") ? true : false
    def vcf_name = vcf.getName().replace(".gz", "")

    """
    NUM_SAMPLES=\$(cat $samplelist | wc -l)
    if [ $max_perc_amb_samples > 0 ]; then
        MAX_AMB_SAMPLES=\$(echo "\${NUM_SAMPLES} $max_perc_amb_samples" | awk '{x=\$1*(\$2/100); y=int(x); x=(y<1?1:y)} END {print x}')
    else
        MAX_AMB_SAMPLES=$max_amb_samples
    fi

    if [ "$is_compressed_vcf" == "true" ]; then
        gzip -c -d $vcf > $vcf_name
    fi

    python $projectDir/bin/broad-vcf-filter/vcfSnpsToFasta.py --max_amb_samples \$MAX_AMB_SAMPLES --min_depth $min_depth $vcf_name > ${prefix}_vcf-to-fasta.fasta
    echo "NUM_SAMPLES=\$NUM_SAMPLES" >> log.txt
    echo "MAX_PERC_AMB_SAMPLES=$max_perc_amb_samples" >> log.txt
    echo "MAX_AMB_SAMPLES=\$MAX_AMB_SAMPLES" >> log.txt
    echo "MIN_DEPTH=$min_depth" >> log.txt

    """

}
