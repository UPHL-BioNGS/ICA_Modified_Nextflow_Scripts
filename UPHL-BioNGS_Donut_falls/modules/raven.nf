process raven {
  tag "${sample}"

  publishDir  = [ path: params.outdir, mode: 'copy' ]

  container 'staphb/raven:1.5.1'

  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-xlarge'

  errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

  cpus   = { 14 }
  memory = { 58.GB }

  input:
  tuple val(sample), file(fastq)

  output:
  tuple val(sample), file("raven/${sample}/${sample}.fasta"),   emit: fasta
  path("raven/${sample}/*"),                                    emit: directory
  path("logs/raven/${sample}.${workflow.sessionId}.{log,err}"), emit: logs

  shell:
  '''
    mkdir -p raven/!{sample} logs/raven
    log_file=logs/raven/!{sample}.!{workflow.sessionId}.log
    err_file=logs/raven/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    raven --version 2>> $err_file >> $log_file

    raven !{params.raven_options} \
      --threads !{task.cpus} \
      --graphical-fragment-assembly raven/!{sample}/!{sample}.gfa \
      !{fastq} \
      2>> $err_file \
      > raven/!{sample}/!{sample}.fasta
  '''
}
