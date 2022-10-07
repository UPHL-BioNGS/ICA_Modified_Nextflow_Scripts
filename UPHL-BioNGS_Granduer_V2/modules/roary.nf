process roary {
  tag "Core Genome Alignment"
  pod annotation: 'scheduler.illumina.com/presetSize' , value: 'hicpu-small'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir = [ path: params.outdir, mode: 'copy' ]
  container  'staphb/roary:3.13.0'
  cpus   = { 15 }
  memory = { 30.GB }
  time   = { 24.h  }
  maxForks 10

  when:
  params.phylogenetic_processes =~ /roary/

  input:
  file(contigs)

  output:
  path "roary/*"                                                             , emit: roary_files
  path "roary/fixed_input_files/*"                                           , emit: roary_input_files
  path "roary/core_gene_alignment.aln"                                       , emit: core_gene_alignment
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.{log,err}", emit: log_files

  shell:
  '''
    mkdir -p logs/!{task.process}
    log_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log
    err_file=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.err

    # time stamp + capturing tool versions
    date | tee -a $log_file $err_file > /dev/null
    roary -a >> $log_file
    echo "container : !{task.container}" >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file

    echo "There are $(ls *gff | wc -l) files for alignment" >> $log_file

    roary !{params.roary_options} \
      -p !{task.cpus} \
      -f roary \
      -e -n \
      *.gff \
      2>> $err_file >> $log_file
  '''
}
