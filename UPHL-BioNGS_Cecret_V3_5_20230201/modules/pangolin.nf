process pangolin {
  tag "SARS-CoV-2 lineage Determination"

  publishDir    params.outdir, mode: 'copy'

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-xlarge'
  memory 60.GB
  cpus 14

  time '45m'

  container      = 'staphb/pangolin:latest'

  when:
  params.pangolin

  input:
  file(fasta)

  output:
  path "pangolin/*",                                                            emit: results
  path "pangolin/lineage_report.csv",                                           emit: pangolin_file
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p pangolin logs/!{task.process}
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log
    pangolin --all-versions >> $log

    for fasta in !{fasta}
    do
      cat $fasta >> ultimate_fasta.fasta
    done

    pangolin !{params.pangolin_options} \
      --threads !{task.cpus} \
      --outdir pangolin \
      ultimate_fasta.fasta \
      | tee -a $log
    cp ultimate_fasta.fasta pangolin/combined.fasta
  '''
}
