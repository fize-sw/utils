#!/bin/sh

FILTERED_URINE_DIR=Filtered-Urine
NBP_DIR=Monitor-NBP
LOG_DIR=Log
RECORD_SHEET_I_DIR=Record-sheet-I
MONITOR_DIR=Monitor

RESULTS_DIR=results
FILTERED_URINE_RES_DIR=$RESULTS_DIR/$FILTERED_URINE_DIR
LOG_RES_DIR=$RESULTS_DIR/$LOG_DIR
NBP_RES_DIR=$RESULTS_DIR/$NBP_DIR
RECORD_SHEET_I_RES_DIR=$RESULTS_DIR/$RECORD_SHEET_I_DIR
MONITOR_RES_DIR=$RESULTS_DIR/$MONITOR_DIR

PATIENT_FILE=""
message="Patient's record file is missing : "

get_epoch_start()
{
        # compute patient epoch start time
        d=`cat $PATIENT_FILE | grep -v "Start" | cut -d"," -f2 | awk '{ split ($1, a, "/"); print a[3] "-" a[2] "-" a[1] " " $2 }'`
        d1=`echo $d | cut -d " " -f1`
        epoch_start_date=`date -d $d1 +%s`
        epoch_start_time=`echo $d | cut -d" " -f2 | awk '{split ($1,a,":") ; printf("%d", a[3]+a[2]*60+a[1]*3600) }'`
        epoch_start=$((epoch_start_date+$((epoch_start_time))))
}

# prepare result directories
mkdir -p $RESULTS_DIR
mkdir -p $NBP_RES_DIR
mkdir -p $NBP_RES_DIR/backup
mkdir -p $LOG_RES_DIR
mkdir -p $RECORD_SHEET_I_RES_DIR
mkdir -p $FILTERED_URINE_RES_DIR
cp -rp $MONITOR_DIR $RESULTS_DIR

filtered_urine_files=`ls $FILTERED_URINE_DIR`
for fu in $filtered_urine_files; do
	src_file=$FILTERED_URINE_DIR/$fu
	dst_file_1=$FILTERED_URINE_RES_DIR/Polynomal_$fu
	dst_file_2=$FILTERED_URINE_RES_DIR/Polynomal2_$fu
	cat $src_file | awk 'BEGIN{start=1}; {if ($1=="-999") start=1; if (start==0) print $0 ; if ($1=="Polynomial") start=0;}' > $dst_file_1
	cat $src_file | awk 'BEGIN{start=1}; {if ($1=="-999") start=1; if (start==0) print $0 ; if ($1=="Polynomial2") start=0;}' > $dst_file_2
done

# Prpare epoch start time for each patient
log_files=`ls $LOG_DIR | grep -v xlsx`
for l in $log_files ; do
        PATIENT_FILE="$LOG_DIR/$l"
        get_epoch_start
	id=`echo $l | sed 's/[a-z,.]//g' | sed 's/^0*//'`
        echo $epoch_start > $LOG_RES_DIR/$id.csv
done

# Prepare Monitr_NBP
NBP_summary_file=$NBP_RES_DIR/summary_file.txt
mv -f $NBP_summary_file $NBP_RES_DIR/backup/ 2>> /dev/null

nbp_files=`ls $NBP_DIR`
for m in $nbp_files ; do
	# check if patient record exist
	id=`echo $m | cut -d"-" -f2 | cut -d"." -f1 |sed 's/[a-z,.]//g' | sed 's/^0*//'`
        PATIENT_FILE=$LOG_RES_DIR/$id.csv
	[ ! -f  $PATIENT_FILE ] && { echo $message $src_file >> $NBP_summary_file; continue; }
	p_epoch_start_time=`cat $PATIENT_FILE`

	src_file=$NBP_DIR/$m
        pre_file=$NBP_RES_DIR/pre-$m

	cat $src_file | awk -F "," '{a=gensub(/[/:]/," ","g",$1) ; split(a, b, " "); c=b[3]" "b[2]" "b[1]" "b[4]" "b[5]" 0"; print mktime(c)","$2}' > $pre_file

	src_file=$pre_file
	dst_file=$NBP_RES_DIR/$m

	# backup old file
	mkdir -p $NBP_RES_DIR/backup
	mv $dst_file $NBP_RES_DIR/backup/  2>> /dev/null

	cat $src_file | awk -F"," '{ print $1-v","$2  }' v="${p_epoch_start_time}" > $dst_file
done

# prepare Record_sheet-I
REC_summary_file=$RECORD_SHEET_I_RES_DIR/summary_file.txt
mv -f $REC_summary_file $RECORD_SHEET_I_RES_DIR/backup/ 2>> /dev/null

rec_i_files=`ls $RECORD_SHEET_I_DIR`
for s in $rec_i_files; do

	# check if Patient's info record exist
	id=`echo $s | sed 's/[a-z,.]//g' | sed 's/^0*//'`
        PATIENT_FILE=$LOG_RES_DIR/$id.csv
	[ ! -f  $PATIENT_FILE ] && { echo $message $src_file >> $REC_summary_file; continue; }
	p_epoch_start_time=`cat $PATIENT_FILE`

	src_file=$RECORD_SHEET_I_DIR/$s
        pre_file=$RECORD_SHEET_I_RES_DIR/pre-$s

	cat $src_file |  awk -F"," 'NR==1{} NR>1{a=gensub(/[/:]/," ","g",$2) ; split(a, b, " "); split($4,c,":"); d=b[3]" "b[2]" "b[1]" "c[1]" "c[2]" 0"; print mktime(d)","$NF}' > $pre_file
#        cat $src_file |  awk -F"," 'NR==1{print $0} NR>1{a=gensub(/[/:]/," ","g",$2) ; split(a, b, " "); c=b[3]" "b[2]" "b[1]" "b[4]" "b[5]" 0"; printf "%s,%s", $1,mktime(c) ;for(i=3;i<=NF;i++){printf ",%s", $i} printf "\n"}' > $pre_file

	src_file=$pre_file
	dst_file=$RECORD_SHEET_I_RES_DIR/$s

	# backup old file
	mkdir -p $RECORD_SHEET_I_RES_DIR/backup
	mv $dst_file $RECORD_SHEET_I_RES_DIR/backup/ 2>> /dev/null 

	cat $src_file | awk -F"," '{ print $1-v","$2; }' v="${p_epoch_start_time}" > $dst_file
#	cat $src_file | awk -F"," 'NR==1{print $0} NR>1{ printf "%s,%s",$1,$2-v; for(i=3;i<=NF;i++){printf ",%s", $i}; printf "\n" }' v="${p_epoch_start_time}" > $dst_file
done

rm $RESULTS_DIR/*/pre-*

exit 0
