  process miniasm {
  tag "${sample}"

  publishDir  = [ path: params.outdir, mode: 'copy' ]

  container 'staphb/minipolish:0.1.3'

  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-xlarge'

  errorStrategy { task.attempt < 4 ? 'retry' : 'ignore'}

  cpus   = { 14 }
  memory = { 58.GB }

  input:
  tuple val(sample), file(fastq)

  output:
  tuple val(sample), path("miniasm/${sample}/*gfa"),             emit: gfa
  path "miniasm/${sample}/*",                                    emit: directory
  path "logs/miniasm/${sample}.${workflow.sessionId}.{log,err}", emit: logs

  shell:
  '''
    mkdir -p miniasm/!{sample} logs/miniasm
    log_file=logs/miniasm/!{sample}.!{workflow.sessionId}.log
    err_file=logs/miniasm/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    echo "miniasm version : $(miniasm -V)" 2>> $err_file >> $log_file
    minimap2 --version 2>> $err_file >> $log_file
    minipolish --version 2>> $err_file >> $log_file

    miniasm_and_minipolish.sh \
      !{fastq} \
      !{task.cpus} \
      2>> $err_file > miniasm/!{sample}/!{sample}.gfa
  '''
}
