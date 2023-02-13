process nextalign {
  tag "Multiple Sequence Alignment"

  publishDir    params.outdir, mode: 'copy'

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-xlarge'
  memory 60.GB
  cpus 14

  time '45m'

  container     = 'nextstrain/nextalign:latest'

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
