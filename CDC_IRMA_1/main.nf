#!/usr/bin/env nextflow

params.outdir = workflow.launchDir + '/out/'

params.reads = workflow.launchDir + '/reads'

Channel
  .fromFilePairs(["${params.reads}/*_R{1,2}*.{fastq,fastq.gz,fq,fq.gz}",
                  "${params.reads}/*_{1,2}*.{fastq,fastq.gz,fq,fq.gz}"], size: 2 )
  .map { reads -> tuple(reads[0].replaceAll(~/_S[0-9]+_L[0-9]+/,""), reads[1]) }
  .view { "Paired-end fastq files found : ${it[0]}" }
  .into { reads_check ; reads }

reads_check.ifEmpty{
  println("FATAL : No fastq or fastq.gz files were found at ${params.reads}")
  println("Set 'params.reads' to directory with paired-end reads" )
  exit 1
}

process irma {
    publishDir "${params.outdir}", mode: 'copy'
    tag "${sample}"
    cpus 3
    container 'staphb/irma:1.0.2'
    pod annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-medium'

    when:
    sample != null

    input:
    tuple val(sample), file(reads) from reads

    output:
    path("${task.process}/${sample}")

    shell:
    '''
      IRMA FLU !{reads[0]} !{reads[1]} !{task.process}/!{sample}
    '''
}
