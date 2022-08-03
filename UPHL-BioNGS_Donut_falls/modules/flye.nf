process flye {
  tag "${sample}"

  publishDir  = [ path: params.outdir, mode: 'copy' ]

  container 'staphb/flye:2.9'

  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-xlarge'

  errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

  cpus   = { 14 }
  memory = { 58.GB }

  input:
  tuple val(sample), file(fastq)

  output:
  tuple val(sample), file("flye/${sample}/${sample}.fasta"), optional: true,  emit: fasta
  tuple val(sample), file("flye/${sample}/assembly_info.txt"),                emit: info
  path "flye/${sample}",                                                      emit: directory
  path "logs/flye/${sample}.${workflow.sessionId}.{log,err}",                 emit: logs

  shell:
  '''
    mkdir -p logs/flye flye/!{sample}
    log_file=logs/flye/!{sample}.!{workflow.sessionId}.log
    err_file=logs/flye/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    flye --version 2>> $err_file >> $log_file

    flye !{params.flye_options} \
      --nano-raw !{fastq} \
      --threads !{task.cpus} \
      --out-dir flye/!{sample} \
      2>> $err_file >> $log_file

    if [ -f "flye/!{sample}/assembly.fasta" ] ; then cp flye/!{sample}/assembly.fasta flye/!{sample}/!{sample}.fasta ; fi
  '''
}
