process QC_REPORTSHEET {
    label 'process_low'

    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'himem-small'
    cpus 6
    memory '48 GB'
    time '1day'
    maxForks 10

    errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

    ext.when         = {  }
    publishDir       = [
            enabled: true,
            mode: "${params.publish_dir_mode}",
            path: { "${params.outdir}/stats/qc_report" },
            pattern: "*",
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]

    input:
    path(qc_lines)

    output:
    path("qc_report.txt"), emit: qc_reportsheet

    script:
    """
    printf \"Sample Name\\tReads Before Trimming\\tGC Before Trimming\\tAverage Q Score Before Trimming\\tReference Length Coverage Before Trimming\\tReads After Trimming\\tPaired Reads After Trimming\\tUnpaired Reads After Trimming\\tGC After Trimming\\tAverage Q Score After Trimming\\tReference Length Coverage After Trimming\\tMean Coverage Depth\\tReads Mapped\\n\" > qc_report.txt
    sort ${qc_lines} > sorted.txt
    cat sorted.txt >> qc_report.txt
    """
}
