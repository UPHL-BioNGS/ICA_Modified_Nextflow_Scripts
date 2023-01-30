process snp_dists {
  tag "SNP matrix"
  publishDir    params.outdir, mode: 'copy'
  container     'staphb/snp-dists:0.8.2'
  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3
  
  input:
  file(contigs)

  output:
  path "snp-dists/snp_matrix.txt"                                      , emit: snp_matrix
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log", emit: log_files

  shell:
  '''
    mkdir -p snp-dists logs/!{task.process}
    log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log_file
    snp-dists -v >> $log_file
    echo "container : !{task.container}" >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file

    snp-dists !{params.snp_dists_options} \
      !{contigs} \
      > snp-dists/snp_matrix.txt
  '''
}
