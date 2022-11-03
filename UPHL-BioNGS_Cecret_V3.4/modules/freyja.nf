process freyja {
  tag           "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/freyja:1.3.11'
  maxForks      10
  cpus          4

  when:
  params.freyja

  input:
  tuple val(sample), file(bam), file(reference_genome)

  output:
  path "freyja/${sample}_demix.tsv",                                      emit: freyja_demix
  path "freyja/${sample}*",                                               emit: files
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p freyja logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    date > $log
    freyja --version >> $log

    freyja variants !{params.freyja_variants_options} \
      !{bam} \
      --variants freyja/!{sample}_variants.tsv \
      --depths freyja/!{sample}_depths.tsv \
      --ref !{reference_genome} \
      | tee -a $log

    freyja demix \
      !{params.freyja_demix_options} \
      freyja/!{sample}_variants.tsv \
      freyja/!{sample}_depths.tsv \
      --output freyja/!{sample}_demix.tsv \
      | tee -a $log

    freyja boot \
      freyja/!{sample}_variants.tsv \
      freyja/!{sample}_depths.tsv \
      --nt !{task.cpus} \
      --output_base freyja/!{sample}_boot.tsv \
      | tee -a $log
  '''
}

process freyja_aggregate {
  tag           "Aggregating results from freyja"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/freyja:1.3.11'
  maxForks      10
  cpus          4

  when:
  params.freyja_aggregate

  input:
  file(demix)

  output:
  path "freyja/aggregated*",                                                   emit: files
  path "freyja/aggregated-freyja.tsv",                                         emit: aggregated_freyja_file
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p freyja logs/!{task.process} tmp
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log

    mv !{demix} tmp/.

    freyja aggregate !{params.freyja_aggregate_options} \
      tmp/ \
      --output freyja/aggregated-freyja.tsv \
      | tee -a $log

    freyja plot !{params.freyja_plot_options} \
      freyja/aggregated-freyja.tsv \
      --output freyja/aggregated-freyja.!{params.freyja_plot_filetype} \
      | tee -a $log
  '''
}
