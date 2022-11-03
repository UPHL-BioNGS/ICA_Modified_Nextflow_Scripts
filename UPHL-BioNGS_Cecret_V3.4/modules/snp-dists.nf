process snpdists {
  tag           "creating snp matrix with snp-dists"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/snp-dists:0.8.2'
  maxForks      10
  cpus          4

  when:
  params.snpdists

  input:
  file(msa)

  output:
  path "snp-dists/snp-dists.txt", emit: matrix
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p snp-dists logs/!{task.process}
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log
    snp-dists -v >> $log

    snp-dists !{params.snpdists_options} !{msa} > snp-dists/snp-dists.txt
  '''
}
