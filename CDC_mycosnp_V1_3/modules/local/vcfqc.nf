process VCF_QC {
    tag "vcf-qc"
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'ignore' }
    maxRetries    = 1
    maxErrors     = '-1'

    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/combined/vcf-qc-report" },
            pattern: "*.{txt}"
        ]

    input:
    path(vcffasta)

    output:
    path("vcf-qc-report.txt"),   emit: vcf_qc_report


	script:
	"""
    printf "Sample Name\\tLength\\tNumber-N\\n" > vcf-qc-report.txt
    awk '\$0 ~ ">" {if (NR > 1) {print c "\\t" d;} c=0;d=0;printf substr(\$0,2,200) "\\t"; } \$0 !~ ">" {c+=length(\$0);d+=gsub(/N/, "");d+=gsub(/n/, "")} END { print c "\\t" d; }' $vcffasta >> vcf-qc-report.txt
	"""
}
