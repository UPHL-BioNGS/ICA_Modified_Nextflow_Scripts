process bcftools_variants {
  tag "${sample}"

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3

  publishDir    params.outdir, mode: 'copy'

  time '45m'

  container      = 'staphb/bcftools:1.16'

  when:
  params.bcftools_variants

  input:
  tuple val(sample), file(bam), file(reference_genome)

  output:
  tuple val(sample), file("bcftools_variants/${sample}.vcf"),             emit: bcftools_variants_file
  tuple val(sample), env(variants_num),                                   emit: bcftools_variants_results
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"

  shell:
  '''
    mkdir -p bcftools_variants logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log
    bcftools --version >> $log

    bcftools mpileup -A -d !{params.mpileup_depth} -B -Q 0 -f !{reference_genome} !{bam} | \
      bcftools call -mv -Ov -o bcftools_variants/!{sample}.vcf | tee -a $log

    variants_num=$(grep -v "#" bcftools_variants/!{sample}.vcf | wc -l)
    if [ -z "$variants_num" ] ; then variants_num="0" ; fi
  '''
}
