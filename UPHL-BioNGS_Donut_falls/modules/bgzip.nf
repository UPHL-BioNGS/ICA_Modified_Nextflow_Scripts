process bgzip {
  tag "${sample}"

  publishDir  = [ path: params.outdir, mode: 'copy' ]

  container 'staphb/htslib:1.15'

  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

  errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

  cpus   = { 1 }
  memory = { 6.GB }

  input:
  tuple val(sample), file(fastq)

  output:
  tuple val(sample), path("filtlong/${fastq}.gz"),                       emit: fastq
  path "logs/bgzip/${sample}.${workflow.sessionId}.{log,err}", emit: logs

  shell:
  '''
    mkdir -p filtlong logs/bgzip
    log_file=logs/bgzip/!{sample}.!{workflow.sessionId}.log
    err_file=logs/bgzip/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    bgzip --version 2>> $err_file >> $log_file

    bgzip -@ !{task.cpus} !{fastq}
    mv !{fastq}.gz filtlong/.
  '''
}
