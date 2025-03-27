# Hardware Suggestions

*Version: 26 March, 2025*

## Choosing the Right Hardware for Your Ceph Cluster

When building a Ceph cluster, selecting the appropriate hardware can be challenging. This guide aims to simplify the process by providing example Bill of Materials (BOMs) that serve as blueprints tailored to specific scenarios and manufacturers.

### Key Considerations

Hardware selection for a Ceph cluster is highly use-case specific. Factors such as workload type, performance expectations, scalability needs, and data center conditions significantly influence the ideal configuration. Ceph's flexibility allows for system designs that can adapt to diverse requirements. While the example BOMs provided in this document are designed to get you started, they might not deliver optimal results for every situation.

**Note:** We assume no liability for the accuracy, availability, or performance of the collection.

### Example BOMs

The following BOMs serve as starting points for commonly encountered use cases:

| Category       | CROIT Mgmt                                                                 | CEPH-NVMe-10BAY                                                                                              | CEPH-HDD-12BAY                                                                                              | CEPH-HDD-24BAY                                                                                              | CEPH-HDD-60BAY                                                                                              |
|----------------|----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| Description    | Runs the croit software, PXE boot stack, centralized logging and statistics | Throughput Optimized Workloads<br><br>VMs, Kubernetes Storage, Database, High performance S3 Object Storage<br><br>Optimal for high performance services. | Capacity Optimized Workloads<br><br>Archive, Backup, price optimized S3 Object Storage, Data Analytics, AI Training Data<br><br>Optimal for clusters no larger than 10 PB | Capacity Optimized Workloads<br><br>Archive, Backup, price optimized S3 Object Storage, Data Analytics, AI Training Data<br><br>Optimal for clusters no larger than 20 PB | Very High Density<br><br> Large - Archive, Backup, price optimized S3 Object Storage, Data Analytics, AI Training Data<br><br>Only suitable for clusters larger than 15 PB |
| Hardware Specs | - 1U super cost effective<br>- Small and efficient CPU 8 core<br>- 32 GB memory<br>- 2x NVMe 1.92TB PCIe Gen4+ (software raid for OS)<br>- Dual port 10 GbE NIC | - 1U 10 bay chassis Gen5 with 40 PCIe lanes to the Bays<br>- min 24 CPU cores or more with 48 CPU threads - each >= 2.5 GHz<br>- 3.84/7.68/15.36TB Gen5+ write intensive NVMe's<br>- 128 GB memory<br>- Dual port 25/50/100+ GbE NIC<br>- 1x 1 TB M.2 or 2.5" NVMe for Croit use (with PLP preferably) | - 1U or 2U 12 bay SAS chassis<br>- min 8 CPU cores with 16 CPU threads - each >= 2.2 GHz<br>- 22/24/26 TB CMR SAS HDD<br>- 256 GB memory<br>- Dual port 10 or 25 GbE<br>- 2x 3.84 TB Gen5+ write intensive NVMe for DB/WAL for much lower latency and higher performance<br>- 1x 1 TB M.2 or 2.5" NVMe for Croit use (with PLP preferably) | - 24 bay SAS chassis<br>- min 16 CPU cores with 32 CPU threads - each >= 2.2 GHz<br>- 22/24/26 TB CMR SAS HDD<br>- 256 GB memory<br>- Dual port 10 or 25 GbE<br>- 2x 3.84 TB Gen5+ write intensive NVMe for DB/WAL for much lower latency and higher performance<br>- 1x 1 TB M.2 or 2.5" NVMe for Croit use (with PLP preferably) | - 4U 60 bays SAS chassis<br>- min 32 CPU cores with 64 CPU threads - each >= 2.2 GHz<br>- 22/24/26 TB CMR SAS HDD<br>- 768 GB memory<br>- Dual port 25/50/100 GbE<br>- 4x 7.68 TB Gen5+ write intensive NVMe for DB/WAL for much lower latency and higher performance<br>- 1x 1 TB M.2 or 2.5" NVMe for Croit use (with PLP preferably) |
| Important      |                                                                            | **Important:**<br>- No expander backplane!<br>- Avoid any PCIe switches, retimers, .. where possible.<br>- No raid cards! | **Important:**<br>- Do not add any raid controller. Use a simple HBA<br>- Ensure that the NVMe are directly connected to the CPU | **Important:**<br>- Do not add any raid controller. Use a simple HBA<br>- Ensure that the NVMe are directly connected to the CPU | **Important:**<br>- Do not add any raid controller. Use a simple HBA<br>- Ensure that the NVMe are directly connected to the CPU |
| Optional       | **Optional:**<br>- Use 64 GB memory for larger clusters (30+ servers)      | **Optional:**<br>- Upgrade to 192/256 GB RAM for better performance<br>- Upgrade to more CPU cores for higher overall IOPS<br>- Upgrade to higher CPU frequency for better single client performance<br>- Double the Memory/CPU cores per additional NVMe Namespace | **Optional:**<br>- Upgrade to 192/256 GB RAM for slightly better performance                                      |                                                                                                             |                                                                                                             |

## CephFS MDS Service

Increase CPU cores by 4 or more and increase RAM by 64 GB or more depending on the number of files, clients, and other factors.

For performance reasons, if you expect more than 50k RGW objects or CephFS files, you should equip a separate NVMe 1TB drive per node for RGW/CephFS metadata. Rear slot or M.2 is sufficient. Can use namespace.

**Note:** For large or complex deployments, we offer consulting services to tailor your hardware choices to your needs.

**Note:** Choose dedicated MDS servers with high CPU clock frequency to get the best performance.

## Seagate MACH.2 HDDs

If you want to go with Western Digital or Seagate MACH.2 dual actuator drives[^1], please double the RAM, CPU, and DB/WAL. These drives come with higher IO and bandwidth performance and can benefit your workloads on HDDs.

**Note:** Please be reminded, an HDD is always way slower than an NVMe.

[^1]: [https://www.seagate.com/gb/en/innovation/multi-actuator-hard-drives/](https://www.seagate.com/gb/en/innovation/multi-actuator-hard-drives/)

## SAS SSDs

The cost difference between SAS SSDs vs NVMe is so minimal that we would not recommend SAS SSDs as they are constrained to the bandwidth of the controller, if you find prices being dramatically different contact us to work with our partners for competitive pricing. If you already have SAS SSDs and see performance issues you may see benefits by equipping NVMe’s for DB/WALs as this will shift metadata IOPs from the SAS controller to the NMVe drives.

## Customized Hardware Proposals

Since hardware needs vary greatly, these example BOMs are not a one-size-fits-all solution. As part of our consulting services, we offer tailored hardware recommendations based on your specific use case and operational constraints. Contact us to discuss your requirements and receive a customized proposal.
