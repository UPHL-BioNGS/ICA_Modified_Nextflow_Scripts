process nextalign {
  tag           "Multiple Sequence Alignment"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'nextstrain/nextalign:latest'
  maxForks      10
  cpus          4

  input:
  file(consensus)
  path(dataset)

  output:
  path "nextalign/nextalign.aligned.fasta",                                     emit: msa
  path "nextalign/{*.fasta,nextalign.*.csv}",                                   emit: files
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p nextalign logs/!{task.process}
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log
    echo "nextalign version:" >> $log
    nextalign --version >> $log

    for fasta in !{consensus}
    do
      cat $fasta >> nextalign/ultimate.fasta
    done

    nextalign run !{params.nextalign_options} \
      --input-ref=!{dataset}/reference.fasta \
      --genemap=!{dataset}/genemap.gff \
      --jobs !{task.cpus} \
      --output-all=nextalign/ \
      nextalign/ultimate.fasta \
      | tee -a $log
  '''
}
