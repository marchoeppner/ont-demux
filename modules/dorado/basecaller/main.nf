process DORADO_BASECALLER {
    label 'gpu'
    label 'basecalling'

    container "ontresearch/dorado:shac8f356489fa8b44b31beba841b84d2879de2088e" // 1.4.0

    input:
    tuple val(meta), path(pod5), val(samplesheet)
    val(model)
    val(duplex)

    output:
    tuple val(meta), path("bam_pass"), emit: called
    path('versions.yml'), emit: versions

    script:

    def args = task.ext.args ?: ''
    def options = samplesheet ? "--sample-sheet $samplesheet" : ""
    def mode = duplex ? "duplex" : "basecaller"

    """
    dorado $mode \
    $model \
    $pod5 \
    --models-directory \$DRD_MODELS_PATH \
    -o basecalling \
    $options \
    $args 

    find ./ -name bam_pass -exec cp -R {} . \\;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | tail -n1)
    END_VERSIONS
    """

}
