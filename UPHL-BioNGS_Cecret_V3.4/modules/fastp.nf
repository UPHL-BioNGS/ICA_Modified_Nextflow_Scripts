process fastp {
  tag "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/fastp:0.23.2'
  maxForks      10
  cpus          4

  when:
  sample != null

  input:
  tuple val(sample), file(reads), val(paired_single)

  output:
  tuple val(sample), file("fastp/${sample}_clean_PE{1,2}.fastq.gz"),                                 optional: true,  emit: paired_files
  tuple val(sample), file("fastp/${sample}_cln.fastq.gz"),                                           optional: true,  emit: single_files
  tuple val(sample), file("fastp/${sample}_{clean_PE1,clean_PE2,cln}.fastq.gz"), val(paired_single), optional: true,  emit: clean_reads
  path "fastp/${sample}_fastp.html",                                                                                  emit: html
  path "fastp/${sample}_fastp.json",                                                                                  emit: fastp_files
  path "logs/${task.process}/${sample}.${workflow.sessionId}.{log,err}"
  tuple val(sample), env(passed_reads),                                                                               emit: fastp_results
  tuple val(sample), env(cleaner_version),                                                                            emit: cleaner_version

  shell:
  if ( paired_single == 'paired' ) {
    '''
      mkdir -p fastp logs/!{task.process}
      log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log
      err=logs/!{task.process}/!{sample}.!{workflow.sessionId}.err

      # time stamp + capturing tool versions
      date > $log
      fastp --version >> $log
      cleaner_version="$(fastp --version 2>&1 | head -n 1)"

      fastp !{params.fastp_options} \
        -i !{reads[0]} \
        -I !{reads[1]} \
        -o fastp/!{sample}_clean_PE1.fastq.gz \
        -O fastp/!{sample}_clean_PE2.fastq.gz \
        -h fastp/!{sample}_fastp.html \
        -j fastp/!{sample}_fastp.json \
        2>> $err | tee -a $log

      passed_reads=$(grep "reads passed filter" $err | tail -n 1 | cut -f 2 -d ":" | sed 's/ //g' )
      if [ -z "$passed_reads" ] ; then passed_reads="0" ; fi
    '''
  } else if ( paired_single == 'single' ) {
    '''
      mkdir -p fastp logs/!{task.process}
      log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log
      err=logs/!{task.process}/!{sample}.!{workflow.sessionId}.err

      # time stamp + capturing tool versions
      date > $log
      fastp --version >> $log
      cleaner_version="$(fastp --version 2>&1 | head -n 1)"

      fastp !{params.fastp_options} \
        -i !{reads} \
        -o fastp/!{sample}_cln.fastq.gz \
        -h fastp/!{sample}_fastp.html \
        -j fastp/!{sample}_fastp.json \
        2>> $err | tee -a $log

      passed_reads=$(grep "reads passed filter" $err | tail -n 1 | cut -f 2 -d ":" | sed 's/ //g' )
      if [ -z "$passed_reads" ] ; then passed_reads="0" ; fi
    '''
  }
}
