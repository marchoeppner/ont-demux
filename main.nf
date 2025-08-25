#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
===============================
ONT demux pipeline Pipeline
===============================

This Pipeline performs basecalling and demultiplexing with Dorado

### Homepage / git
git@github.com:marchoeppner/ont-demux.git

**/

// Pipeline version
params.version = workflow.manifest.version

include { ONT_DEMUX }           from './workflows/ont_demux'
include { PIPELINE_COMPLETION } from './subworkflows/pipeline_completion'
include { paramsSummaryLog }    from 'plugin/nf-schema'

workflow {

    multiqc_report = Channel.from([])
    if (!workflow.containerEngine) {
        log.info "\033[1;31mConda is not currently supported.\033[0m"
        System.exit(1)
    }

    WorkflowMain.initialise(workflow, params, log)
    WorkflowPipeline.initialise(params, log)

    // Print summary of supplied parameters
    log.info paramsSummaryLog(workflow)

    ONT_DEMUX()

    multiqc_report = multiqc_report.mix(ONT_DEMUX.out.qc).toList()
    
    // Reporting worfklow
    PIPELINE_COMPLETION()

}
