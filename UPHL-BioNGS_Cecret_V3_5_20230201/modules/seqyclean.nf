process seqyclean {
  tag "${sample}"

  publishDir    params.outdir, mode: 'copy'

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3

  time '45m'

  container     = 'staphb/seqyclean:1.10.09'

  when:
  sample != null

  input:
  tuple val(sample), file(reads), val(paired_single)

  output:
  tuple val(sample), file("seqyclean/${sample}_clean_PE{1,2}.fastq.gz"),                                    optional: true, emit: paired_reads
  tuple val(sample), file("seqyclean/${sample}_cln_SE.fastq.gz"),                                           optional: true, emit: single_reads
  tuple val(sample), file("seqyclean/${sample}_{cln_SE,clean_PE1,clean_PE2}.fastq.gz"), val(paired_single), optional: true, emit: clean_reads
  path "seqyclean/${sample}_clean_SummaryStatistics.tsv",                                                   optional: true, emit: seqyclean_files_collect_paired
  path "seqyclean/${sample}_cln_SummaryStatistics.tsv",                                                     optional: true, emit: seqyclean_files_collect_single
  path "seqyclean/${sample}_cl*n_SummaryStatistics.txt",                                                                    emit: txt
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"
  tuple val(sample), env(cleaner_version),                                                                                  emit: cleaner_version

  shell:
  if ( paired_single == "single" ) {
  '''
    mkdir -p seqyclean logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log
    echo "seqyclean version: $(seqyclean -h | grep Version)" >> $log
    cleaner_version="seqyclean : $(seqyclean -h | grep Version)"

    seqyclean !{params.seqyclean_options} \
      -c !{params.seqyclean_contaminant_file} \
      -U !{reads} \
      -o seqyclean/!{sample}_cln \
      -gz \
      | tee -a $log
  '''
  } else if ( paired_single == 'paired' ) {
  '''
    mkdir -p seqyclean logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log
    echo "seqyclean version: $(seqyclean -h | grep Version)" >> $log
    cleaner_version="seqyclean : $(seqyclean -h | grep Version)"

    seqyclean !{params.seqyclean_options} \
      -c !{params.seqyclean_contaminant_file} \
      -1 !{reads[0]} -2 !{reads[1]} \
      -o seqyclean/!{sample}_clean \
      -gz \
      | tee -a $log
  '''
  }
}
