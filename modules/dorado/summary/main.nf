process DORADO_SUMMARY {
    label 'gpu'
    label 'short_serial'

    container "ontresearch/dorado:mr661_shae423e761540b9d08b526a1eb32faf498f32e8f22"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.txt"), emit: txt
    path('versions.yml'), emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    """
    dorado summary \
    $bam \
    $args > ${prefix}_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | tail -n1)
    END_VERSIONS
    """

}
