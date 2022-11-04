process minimap2 {
  tag           "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "out/cecret", mode: 'copy'
  container     'staphb/minimap2:2.24'
  maxForks      10
  cpus          4

  input:
  tuple val(sample), file(reads), file(reference_genome)

  output:
  tuple val(sample), file("aligned/${sample}.sam"),                       emit: sam
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"
  tuple val(sample), env(minimap2_version),                               emit: aligner_version

  shell:
  '''
    mkdir -p aligned logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log
    minimap2 --version >> $log
    minimap2_version=$(echo "minimap2 : "$(minimap2 --version))

    minimap2 !{params.minimap2_options} \
      -ax sr -t !{task.cpus} \
      -o aligned/!{sample}.sam \
      !{reference_genome} !{reads} \
      | tee -a $log
  '''
}
