#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// TODO: Update this block with a description and the name of the pipeline
/**
===============================
Pipeline
===============================

This Pipeline performs ....

### Homepage / git
git@github.com:marchoeppner/pipeline.git

**/

// Pipeline version
params.version = workflow.manifest.version

// TODO: Rename this to something matching this pipeline, e.g. "AMPLICONS"
include { MAIN }                from './workflows/main'
include { PIPELINE_COMPLETION } from './subworkflows/pipeline_completion'
include { paramsSummaryLog }    from 'plugin/nf-schema'

workflow {

    def summary = [:]

    multiqc_report = Channel.from([])
    if (!workflow.containerEngine) {
        log.info "\033[1;31mRunning with Conda is not recommended in production!\033[0m\n\033[0;31mConda environments are not guaranteed to be reproducible - for a discussion, see https://pubmed.ncbi.nlm.nih.gov/29953862/.\033[0m"
    }

    WorkflowMain.initialise(workflow, params, log)
    // TODO: Rename this and the file under lib/ to something matching this pipeline (e.g. WorkflowAmplicons)
    WorkflowPipeline.initialise(params, log)

    // Print summary of supplied parameters
    log.info paramsSummaryLog(workflow)

    // TODO: Rename to something matching this pipeline (see above)
    MAIN()

    multiqc_report = multiqc_report.mix(MAIN.out.qc).toList()
    
    // Reporting worfklow
    PIPELINE_COMPLETION()

}
