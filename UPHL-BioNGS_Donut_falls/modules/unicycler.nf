process unicycler {
  tag "${sample}"

  publishDir  = [ path: params.outdir, mode: 'copy' ]

  container 'staphb/unicycler:0.5.0'

  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-xlarge'

  errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

  cpus   = { 14 }
  memory = { 58.GB }

  input:
  tuple val(sample), file(nanopore), file(illumina)

  output:
  path "unicycler/${sample}",                                       emit: directory
  tuple val(sample), file("unicycler/${sample}/assembly.fasta"),    emit: fasta
  path "logs/unicycler/${sample}.${workflow.sessionId}.{log,err}",  emit: logs

  shell:
  '''
    mkdir -p unicycler logs/unicycler
    log_file=logs/unicycler/!{sample}.!{workflow.sessionId}.log
    err_file=logs/unicycler/!{sample}.!{workflow.sessionId}.err

    date | tee -a $log_file $err_file > /dev/null
    unicycler --version >> $log_file

    unicycler !{params.unicycler_options} \
      -1 !{illumina[0]} \
      -2 !{illumina[1]} \
      -l !{nanopore} \
      -o unicycler/!{sample} \
      -t 20 \
      2>> $err_file >> $log_file
  '''
}
