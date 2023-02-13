process iqtree2 {
  tag "Creating phylogenetic tree with iqtree"
  label "maxcpus"

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-xlarge'
  memory 60.GB
  cpus 14

  publishDir    params.outdir, mode: 'copy'

  time '45m'

  container       = 'staphb/iqtree2:2.1.2'

  when:
  params.iqtree2

  input:
  file(msa)

  output:
  path "iqtree2/iqtree2.{iqtree,treefile,mldist,log}", emit: tree
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p iqtree2 logs/!{task.process}
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log
    iqtree2 --version >> $log

    if [ -n "!{params.iqtree2_outgroup}" ] && [ "!{params.iqtree2_outgroup}" != "null" ] && [ "!{params.msa}" != "nextclade" ]
    then
      outgroup="-o !{params.iqtree2_outgroup}"
      cat !{msa} | sed 's/!{params.iqtree2_outgroup}.*/!{params.iqtree2_outgroup}/g' > !{msa}.renamed
    else
      outgroup=""
      mv !{msa} !{msa}.renamed
    fi

    # creating a tree
    iqtree2 !{params.iqtree2_options} \
      -nt AUTO \
      -ntmax !{task.cpus} \
      -s !{msa}.renamed \
      -pre iqtree2/iqtree2 \
      $outgroup \
      | tee -a $log
  '''
}
