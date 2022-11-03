process mafft {
  tag           "Multiple Sequence Alignment"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/mafft:7.475'
  maxForks      10
  cpus          4
  
  input:
  file(fasta)
  file(reference_genome)

  output:
  path "mafft/mafft_aligned.fasta",                                   emit: msa
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p mafft logs/!{task.process}
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log
    echo "mafft version:" >> $log
    mafft --version 2>&1 >> $log

    for fasta in !{fasta}
    do
      cat $fasta >> mafft/ultimate.fasta
    done

    mafft --auto \
      !{params.mafft_options} \
      --thread !{task.cpus} \
      --addfragments mafft/ultimate.fasta \
      !{reference_genome} \
      > mafft/mafft_aligned.fasta
  '''
}
