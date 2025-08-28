# Pipeline structure

The following steps are performed:

- Read pod5 folder
- Check for a valid samplesheet
- Run Dorado Basecalling (incl. demultiplexing if the kit suggests barcoding was used)
- Split basecalling results into individual bam files
  - perform fastQ conversion for each BAM file (attaching the sample alias, if defined)
- Generate basecalling metrics using Dorado Summary
- Plot metrics using Nanoplot
- Combine results in MultiQC report


