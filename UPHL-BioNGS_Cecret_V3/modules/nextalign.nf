process nextalign {
  tag "Multiple Sequence Alignment"
  label "maxcpus"

  container 'nextstrain/nextalign:latest'

  publishDir = [ path: params.outdir, mode: 'copy' ]

  input:
  file(consensus)
  path(dataset)

  output:
  path "nextalign/nextalign.aligned.fasta",                                     emit: msa
  path "nextalign/{*.fasta,nextalign.*.csv}",                                   emit: files
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}",  emit: log

  shell:
  '''
    mkdir -p nextalign logs/!{task.process}
    log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
    err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err

    date | tee -a $log_file $err_file > /dev/null
    echo "nextalign version:" >> $log_file
    nextalign --version-detailed 2>&1 >> $log_file

    for fasta in !{consensus}
    do
      cat $fasta >> nextalign/ultimate.fasta
    done

    nextalign !{params.nextalign_options} \
      --sequences nextalign/ultimate.fasta \
      --reference !{dataset}/reference.fasta \
      --genemap !{dataset}/genemap.gff \
      --jobs !{task.cpus} \
      --output-dir nextalign \
      --output-basename nextalign \
      >> $log_file 2>> $err_file
  '''
}
