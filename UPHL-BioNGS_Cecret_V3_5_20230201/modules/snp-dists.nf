process snpdists {
  tag "createing snp matrix with snp-dists"

  publishDir    params.outdir, mode: 'copy'

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3

  time '45m'

  container     = 'staphb/snp-dists:0.8.2'

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
