process any2fasta {
  tag "${sample}"

  publishDir  = [ path: params.outdir, mode: 'copy' ]

  container 'staphb/any2fasta:0.4.2'

  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

  errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

  cpus   = { 1 }
  memory = { 6.GB }

  input:
  tuple val(sample), file(gfa)

  output:
  tuple val(sample), file("miniasm/${sample}/${sample}.fasta"),               emit: fasta
  path("logs/any2fasta/${sample}.${workflow.sessionId}.{log,err}"), emit: logs

  shell:
  '''
    mkdir -p miniasm/!{sample} logs/any2fasta
    log_file=logs/any2fasta/!{sample}.!{workflow.sessionId}.log
    err_file=logs/any2fasta/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    any2fasta -v 2>> $err_file >> $log_file

    any2fasta \
      !{gfa} \
      2>> $err_file \
      > miniasm/!{sample}/!{sample}.fasta
  '''
}
