# disk
# 手动单块磁盘分区格式化并挂载:
parted -m -s /dev/vdb mklabel gpt mkpart primary 0% 100%
mkfs.ext4 /dev/vdb1

## something you need to define first
disk_type=vd
meta_disk_letter=b
meta_mount_point=/data
# data disks sections
start_letter=b
end_letter=e
start_num=01
end_num=03
data_mount_point_head=/data

## meta_disk
mkdir -p ${meta_mount_point}
meta_disk=/dev/${disk_type}${meta_disk_letter}
parted -m -s ${meta_disk} mklabel gpt mkpart primary 0% 100% && sleep 1
mkfs.ext4 ${meta_disk}1
mount ${meta_disk}1 ${meta_mount_point}

## data_disks
# temp files
mount_point_list=/tmp/sa_mount_point && rm -rf ${mount_point_list}
disk_list=/tmp/sa_disks && rm -rf ${disk_list}

# mkdir mount points
for i in $(seq -w ${start_num} ${end_num});do echo ${data_mount_point_head}${i} >> ${mount_point_list};mkdir -p ${data_mount_point_head}${i};done

# format disks
start_switch=0
for i in {a..z};do \
$(test ${start_switch} == 1) || $(test ${i} == ${start_letter}) && start_switch=1 && \
disk=/dev/${disk_type}${i} && \
echo ${disk} >> ${disk_list} && \
parted -m -s ${disk} mklabel gpt mkpart primary 0% 100% && sleep 1 && \
mkfs.ext4 ${disk}1; \
$(test ${i} == ${end_letter}) && break;done

# mount disks
for i in $(seq -w ${start_num} ${end_num});do mount $(sed -n "${i}p" ${disk_list})1 $(sed -n "${i}p" ${mount_point_list});done

# fstab
sudo lsblk -f -s -d | sed '1d' | sort -k2 -n | awk '{print "UUID="$3"\t"$NF"\t"$2"\tdefaults,noatime\t0 0"}' >> /etc/fstab && mount -a

# hdfs
hdfs diskbalancer  --plan `hostname -f` --thresholdPercentage 2 --bandwidth 30
hdfs diskbalancer -execute $(hdfs dfs -ls $(hdfs dfs -ls /system/diskbalancer | grep $(date "+%Y-%b-%d") 2> /dev/null | awk '{print $NF}' | sort -n | tail -n1) | grep "plan.json" | awk '{print $NF}')
hdfs diskbalancer -query `hostname -f`

host_head="node"
for i in {06..15};do host=${host_head}${i};echo $host;scp hdfs.balancer $host:/tmp/;done
for i in {06..15};do host=${host_head}${i};echo $host;ssh $host "sudo su - hdfs -c 'sh /tmp/hdfs.balancer'";done
