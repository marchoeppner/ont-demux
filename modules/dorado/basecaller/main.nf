process DORADO_BASECALLER {
    label 'gpu'
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "ontresearch/dorado:mr661_shae423e761540b9d08b526a1eb32faf498f32e8f22"

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
