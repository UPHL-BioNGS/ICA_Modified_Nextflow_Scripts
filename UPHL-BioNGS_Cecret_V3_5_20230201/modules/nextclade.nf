process nextclade {
  tag "Clade Determination"

  publishDir    params.outdir, mode: 'copy'


  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-xlarge'
  memory 60.GB
  cpus 14

  time '45m'

  container     = 'nextstrain/nextclade:latest'

  when:
  params.nextclade || params.msa == 'nextalign'

  input:
  file(fasta)

  output:
  path "nextclade/nextclade.csv",                                              emit: nextclade_file
  path "nextclade/*",                                                          emit: results
  path "nextclade/nextclade.aligned.fasta",                                    emit: nextclade_aligned_fasta
  path "dataset",                                                              emit: prepped_nextalign
  path "logs/${task.process}/${task.process}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p nextclade dataset logs/!{task.process}
    log=logs/!{task.process}/!{task.process}.!{workflow.sessionId}.log

    date > $log
    nextclade --version >> $log
    nextclade_version=$(nextclade --version)

    nextclade dataset get --name !{params.nextclade_dataset} --output-dir dataset

    for fasta in !{fasta}
    do
      cat $fasta >> ultimate_fasta.fasta
    done

    nextclade run !{params.nextclade_options} \
      --input-dataset dataset \
      --output-all=nextclade/ \
      --jobs !{task.cpus} \
      ultimate_fasta.fasta \
      | tee -a $log
    cp ultimate_fasta.fasta nextclade/combined.fasta
  '''
}
