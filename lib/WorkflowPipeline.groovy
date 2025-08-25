//
// This file holds functions to validate user-supplied arguments
//

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise( params, log) {
        if (!params.run_name) {
            log.info 'Must provide a run_name (--run_name)'
            System.exit(1)
        }
        if (!params.input && !params.build_references) {
            log.info "Pipeline requires a pod5 directory as input (--input)"
            System.exit(1)
        }
        if (!params.kit) {
            log.info "Must specify a valid ONT kit name (--kit)"
            System.exit(1)
        }
        if (!params.model) {
            log.info "Must specify a valid basecalling model (--model)"
            System.exit(1)
        }
        if (params.model && !params.model.contains("@")) {
            log.info "This does not look like a valid basecalling model - should be e.g. sup@v5.2.0"
            System.exit(1)
        }
    }

}
