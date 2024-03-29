process GATK4_LOCALCOMBINEGVCFS {
    tag "combined"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    conda (params.enable_conda ? "bioconda::gatk4=4.2.5.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.5.0--hdfd78af_0' :
        'quay.io/biocontainers/gatk4:4.2.5.0--hdfd78af_0' }"

    ext.args              = ""
    ext.skip_samples      = params.skip_samples
    ext.skip_samples_file = params.skip_samples_file
    publishDir       = [
                enabled: true,
                mode: "${params.publish_dir_mode}",
                path: { "${params.outdir}/combined/gvcf"},
                pattern: "*{vcf.gz,vcf.gz.tbi}"
            ]


    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    input:
    val meta
    path vcf
    path fasta
    path fasta_fai
    path fasta_dict

    output:
    tuple val(meta), path("*.combined.g.vcf.gz"), path("*.combined.g.vcf.gz.tbi"), emit: combined_gvcf
    path("*.combined.g.vcf.gz"), emit: gvcf
    path("*.combined.g.vcf.gz.tbi"), emit: tbi
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def avail_mem       = 3
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (!task.memory) {
        log.info '[GATK COMBINEGVCFS] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    def skip_samples      = task.ext.skip_samples ?: ''
    def skip_samples_file = task.ext.skip_samples_file ?: ''
    if(skip_samples_file){
        skip_samples = file(skip_samples_file).readLines().collect { line -> line.trim() }.join(",")
    }
    def sample_list       = []
    if(skip_samples != '')
    {

      sample_list = skip_samples.split(',')  // split by comma and put into list
    }

    //def input_files = vcf.collect{"-V ${it}"}.join(' ') // add '-V' to each vcf file
    def input_files = ""
    def sortedVCF = vcf.sort{ a, b -> a.getSimpleName() <=> b.getSimpleName() }

    for (int i=0; i < sortedVCF.size(); i++)
    {
        thisVcf = sortedVCF[i]
        if (!thisVcf.getName().endsWith(".tbi")) {
            include_this = true
            for (int j=0; j < sample_list.size(); j++)
            {
                cmpSample = sample_list[j]

                if(thisVcf.getName().startsWith(cmpSample))
                {
                    include_this = false
                }
            }
            if(include_this)
            {
                input_files += "-V $thisVcf "
            }
        }
    }
    """
	    gatk \\
          --java-options "-Xmx${avail_mem}g" \\
          CombineGVCFs \\
          -R ${fasta} \\
          -O ${prefix}.combined.g.vcf.gz \\
          ${args} \\
          ${input_files}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
