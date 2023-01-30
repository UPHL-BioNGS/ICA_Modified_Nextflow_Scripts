process prokka {
  tag           "${sample}"
  label         "maxcpus"
  publishDir    params.outdir, mode: 'copy'
  container     'staphb/prokka:1.14.5'
  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'himem-small'
  memory 60.GB
  cpus 7

  input:
  tuple val(sample), file(contigs), val(organism)

  when:
  sample != null

  output:
  path "prokka/${sample}/*"                                      , emit: prokka_files
  path "prokka/${sample}/${sample}.txt"                          , emit: for_multiqc
  path "gff/${sample}.gff"                                       , emit: gffs
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log", emit: log

  shell:
  if (organism != null) {
    '''
      mkdir -p prokka gff logs/!{task.process}
      log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

      # time stamp + capturing tool versions
      date > $log_file
      echo "container : !{task.container}" >> $log_file
      prokka -v >> $log_file
      echo "Nextflow command : " >> $log_file
      cat .command.sh >> $log_file

      prokka !{params.prokka_options} \
        --cpu !{task.cpus} \
        --outdir prokka/!{sample} \
        --prefix !{sample} \
        --genus !{organism[0]} \
        --species !{organism[1]} \
        --force !{contigs} \
        | tee -a $log_file

      cp prokka/!{sample}/!{sample}.gff gff/!{sample}.gff
    '''
  } else {
    '''
      mkdir -p prokka gff logs/!{task.process}
      log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

      # time stamp + capturing tool versions
      date > $log_file
      echo "container : !{task.container}" >> $log_file
      prokka -v >> $log_file
      echo "Nextflow command : " >> $log_file
      cat .command.sh >> $log_file

      prokka !{params.prokka_options} \
        --cpu !{task.cpus} \
        --outdir prokka/!{sample} \
        --prefix !{sample} \
        --force !{contigs} \
        | tee -a $log_file

      cp prokka/!{sample}/!{sample}.gff gff/!{sample}.gff
    '''
  }
}
