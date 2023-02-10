#!/usr/bin/bash
#SBATCH --account=bphl-umbrella
#SBATCH --qos=bphl-umbrella
#SBATCH --job-name=pbc_workflow
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20                    #This parameter shoulbe be equal to the number of samples if you want fastest running speed. However, the setting number should be less than the max cpu limit(150). 
#SBATCH --mem=20gb
#SBATCH --time=48:00:00
#SBATCH --output=pbc_standalone.%j.out
#SBATCH --error=pbc_standalone.%j.err


# lima m64344e_221201_205954.hifi_reads.bam HiFiViral_SARS-CoV-2_M13barcodes.fasta m64344e_221201_205954.demux.bam --hifi-preset ASYMMETRIC --biosample-csv barcode_to_biosample.csv --store-unbarcoded --dump-clips --log-level INFO --split-named

#Note: the steps below should be wrapped in Nextflow workflow

mimux --probes HiFiViral_SARS-CoV-2_Enrichment_Probes.fasta --probe-report m64344e_M13_bc1016_F--M13_bc1052_R.mimus_probe_report.tsv --log-level INFO m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.bam m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mimux_trimmed.bam

pbindex m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mimux_trimmed.bam

pbmm2 align --sort --preset HiFi --log-level INFO NC_045512.2.fasta m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mimux_trimmed.bam m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam

samtools mpileup --min-BQ 1 -f NC_045512.2.fasta -s -o m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam.mpileup m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam
samtools depth -q 0 -Q 0 -o m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam.depth m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam

bcftools mpileup --open-prob 25 --indel-size 450 --gap-frac 0.01 --ext-prob 1 --min-ireads 3 --max-depth 1000 --max-idepth 5000 --seed 1984 -h 500 -B -a FORMAT/AD -f NC_045512.2.fasta m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam | bcftools call -mv -Ov | bcftools norm -f NC_045512.2.fasta - | bcftools filter -e 'QUAL < 20' - > m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.variants_bcftools.vcf

VCFCons NC_045512.2.fasta testsample --min_coverage 2 --min_alt_freq 0.5 --vcf_type bcftools --input_depth m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.mapped.bam.depth --input_vcf m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.variants_bcftools.vcf

pbmm2 align --sort --preset HiFi --log-level INFO NC_045512.2.fasta testsample.vcfcons.frag.fasta m64344e_221201_205954.demux.M13_bc1016_F--M13_bc1052_R.consensus_mapped.bam

