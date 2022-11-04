process pangolin {
  tag           "SARS-CoV-2 lineage Determination"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "out/cecret", mode: 'copy'
  container     'staphb/pangolin:latest'
  maxForks      10
  cpus          4
  
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
