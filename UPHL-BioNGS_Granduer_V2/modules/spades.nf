process spades {
  tag           "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "grandeur", mode: 'copy'
  container     'staphb/shigatyper:2.0.1'
  maxForks 10

  when:
  flag =~ 'found'

  input:
  tuple val(sample), file(reads)

  output:
  path "spades/${sample}/*"                                              , emit: files
  tuple val(sample), file("contigs/${sample}_contigs.fa"), optional: true, emit: contigs
  path "logs/${task.process}/${sample}.${workflow.sessionId}.{log,err}"  , emit: log

  shell:
  '''
    mkdir -p spades contigs logs/!{task.process}
    log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log
    err_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    echo "container : !{task.container}" >> $log_file
    spades.py --version >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file

    spades.py !{params.spades_options} \
      -1 !{reads[0]} \
      -2 !{reads[1]} \
      --threads !{task.cpus} \
      -o spades/!{sample} \
      2>> $err_file >> $log_file

    if [ -f "spades/!{sample}/contigs.fasta" ] ; then cp spades/!{sample}/contigs.fasta contigs/!{sample}_contigs.fa ; fi
  '''
}
