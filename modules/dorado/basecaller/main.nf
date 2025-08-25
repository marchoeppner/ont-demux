process DORADO_BASECALLER {
    label 'gpu'
    label 'basecalling'

    /* 
    we scale the run time to the size of the pod5 folder in GB times 2 in hours
    This may not be entirey appropriate, depending on GPU capabilities, see:
    https://github.com/Kirk3gaard/2025-Crowdsource-GPU-basecalling-stats
    Most contemporary GPUs seem to manage >= 1GB/hour when running SUP basecalling. 
    */
    time { (2.h * Math.ceil(pod5.size() / 1024 ** 3)) * task.attempt }

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
