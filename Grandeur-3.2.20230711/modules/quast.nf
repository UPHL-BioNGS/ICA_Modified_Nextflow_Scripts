process quast {
  tag           "${sample}"
  publishDir    params.outdir, mode: 'copy'
  container     'staphb/quast:5.0.2'
  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-xlarge'
  memory 60.GB
  cpus 14
  time '10m'
  
  input:
  tuple val(sample), file(contigs)

  output:
  path "quast/${sample}"                                                     , emit: files
  path "quast/${sample}_quast_report.tsv"                    , optional: true, emit: for_multiqc
  tuple val(sample), file("quast/${sample}_quast_report.tsv"), optional: true, emit: results
  path "quast/${sample}/transposed_report.tsv"               , optional: true, emit: collect
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"            , emit: log

  shell:
  '''
    mkdir -p !{task.process} logs/!{task.process}
    log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log_file
    echo "container : !{task.container}" >> $log_file
    quast.py --version >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file

    quast.py !{params.quast_options} \
      !{contigs} \
      --output-dir quast/!{sample} \
      --threads !{task.cpus} \
      | tee -a $log_file

    if [ -f "quast/!{sample}/report.tsv" ] ; then cp quast/!{sample}/report.tsv quast/!{sample}_quast_report.tsv ; fi

    head -n 1 quast/!{sample}/transposed_report.tsv | awk '{print "sample\\t" $0 }' > quast/!{sample}/transposed_report.tsv.tmp
    tail -n 1 quast/!{sample}/transposed_report.tsv | awk -v sample=!{sample} '{print sample "\\t" $0}' >> quast/!{sample}/transposed_report.tsv.tmp
    mv quast/!{sample}/transposed_report.tsv.tmp quast/!{sample}/transposed_report.tsv
  '''
}
