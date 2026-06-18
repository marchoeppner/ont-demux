process DORADO_BASECALLER {
    label 'gpu'
    label 'basecalling'

    // container "ontresearch/dorado:shac8f356489fa8b44b31beba841b84d2879de2088e" // 1.4.0
    container "ontresearch/dorado:sha38b4ce849afa13eac8075f0b41cecd30799f169b" // 2.0.0

    input:
    path(pod5)
    val(model)
    val(duplex)

    output:
    path("**/*.bam"), emit: called
    path('versions.yml'), emit: versions

    script:

    def args = task.ext.args ?: ''
    def mode = duplex ? "duplex" : "basecaller"

    """
    dorado $mode \
    $model \
    $pod5 \
    --models-directory \$DRD_MODELS_PATH \
    -o basecalling \
    $args 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | tail -n1)
    END_VERSIONS
    """

}
