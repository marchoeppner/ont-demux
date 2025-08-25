//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet.map { m, s -> s}
        .splitCsv(header:true, sep:',')
        .map { row -> check_entry(row) }
        .set { meta }
    emit:
    samplesheet = samplesheet // channel: [ val(meta), [ reads ] ]
    meta
}

def check_entry(LinkedHashMap row) {

    // experiment_id,kit,flow_cell_id,sample_id,flow_cell_product_code,alias,barcode
    def meta = [:]

    if (!row.experiment_id) {
        exit 1, "Samplesheet error - an experiment id is required"
        
    }
    if (!row.kit) {
        exit 1, "Samplesheet error - a kit is required"
    }
    if (!row.barcode) {
        exit 1, "Samplesheet error - a barcode is required"
    }
    
    meta.experiment_id = row.experiment_id
    meta.sample_id = row.alias
    meta.alias = row.alias
    meta.kit = row.kit
    meta.flow_cell_id = row.flow_cell_id
    meta.flow_cell_product_code = row.flow_cell_product_code
    meta.barcode = row.barcode

    return meta
}
