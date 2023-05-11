process SNPEFFR {
	
	pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

	ext.args   = { "-p ${params.positions} -g ${params.genes} -e ${params.exclude} " }
    publishDir = [
                path: { "${params.outdir}/snpeff" },
                mode: params.publish_dir_mode,
                pattern: "*.{csv}"
            ]

	container "ghcr.io/cdcgov/snpeffr:master"
	
	input:
	tuple val(meta), path(input)

	output:
	path '*.csv'		,emit: report
	path "versions.yml"	,emit: versions

	when:
	task.ext.when == null || task.ext.when    

	script:
	def args = task.ext.args ?: ''
	def prefix = task.ext.prefix ?: "${meta.id}"

	"""
	Rscript snpeffr.R -f $input \\
	$args -o ${prefix}.csv
	
	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
	snpeffr: \$(snpeffr --version | sed 's/v//')
	END_VERSIONS
	"""
}
