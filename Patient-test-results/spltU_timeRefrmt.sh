#!/bin/sh

LOG_DIR=Log
NBP_DIR=Monitor-NBP
MONITOR_DIR=Monitor
RECORD_SHEET_I_DIR=Record-sheet-I
FILTERED_URINE_DIR=Filtered-Urine

RESULTS_DIR=results
LOG_RES_DIR=$RESULTS_DIR/$LOG_DIR
NBP_RES_DIR=$RESULTS_DIR/$NBP_DIR
MONITOR_RES_DIR=$RESULTS_DIR/$MONITOR_DIR
RECORD_SHEET_I_RES_DIR=$RESULTS_DIR/$RECORD_SHEET_I_DIR
FILTERED_URINE_RES_DIR=$RESULTS_DIR/$FILTERED_URINE_DIR

ERRORS_FILE=$RESULTS_DIR/errors.txt

PATIENT_FILE=""
message="Patient's record file is missing : "

get_epoch_start()
{
        # compute patient epoch start time
        d=`cat "$PATIENT_FILE" | grep -v "Start" | cut -d"," -f2 | awk '{ split ($1, a, "/"); print a[3] "-" a[2] "-" a[1] " " $2 }'`
        d1=`echo $d | cut -d " " -f1`
        epoch_start_date=`date -d $d1 +%s`
        epoch_start_time=`echo $d | cut -d" " -f2 | awk '{split ($1,a,":") ; printf("%d", a[3]+a[2]*60+a[1]*3600) }'`
        epoch_start=$((epoch_start_date+$((epoch_start_time))))
}

# prepare result directories
rm $ERRORS_FILE 2>> /dev/null
mkdir -p $RESULTS_DIR
mkdir -p $LOG_RES_DIR
mkdir -p $NBP_RES_DIR
mkdir -p $RECORD_SHEET_I_RES_DIR
mkdir -p $FILTERED_URINE_RES_DIR
mkdir -p $MONITOR_RES_DIR

#filtered_urine_files=`ls $FILTERED_URINE_DIR`
#for fu in $filtered_urine_files; do
	#src_file=$FILTERED_URINE_DIR/$fu
	#dst_file_1=$FILTERED_URINE_RES_DIR/Polynomal_$fu
	#dst_file_2=$FILTERED_URINE_RES_DIR/Polynomal2_$fu
	#cat "$src_file" | awk 'BEGIN{start=1}; {if ($1=="-999") start=1; if (start==0) print $0 ; if ($1=="Polynomial") start=0;}' > $dst_file_1
	#cat "$src_file" | awk 'BEGIN{start=1}; {if ($1=="-999") start=1; if (start==0) print $0 ; if ($1=="Polynomial2") start=0;}' > $dst_file_2
#done

# Prpare epoch start time for each patient
log_files=`ls $LOG_DIR | grep -v xlsx`
for Log_file in $log_files ; do
        PATIENT_FILE="$LOG_DIR/$Log_file"
        get_epoch_start
	#id=`echo $Log_file | sed 's/[a-z,.]//g' | sed 's/^0*//'`
	id=`echo $Log_file | cut -d "." -f1`
        echo $epoch_start > $LOG_RES_DIR/$Log_file
done

# Prepare Monitr
monitor_directories=`ls $MONITOR_DIR`
for MON_dir in $monitor_directories ; do
	mkdir -p $MONITOR_RES_DIR/$MON_dir

	# check if patient record exist
	id=$MON_dir
        PATIENT_FILE=$LOG_RES_DIR/$id.csv
	[ ! -f  $PATIENT_FILE ] && { echo $message $MONITOR_DIR/$MON_dir >> $ERRORS_FILE; continue; }
	p_epoch_start_time=`cat $PATIENT_FILE`

	src_file=$MONITOR_DIR/$MON_dir/"ARTmmHg-MEAN - AVG.csv"
	dst_file=$MONITOR_RES_DIR/$MON_dir/"ARTmmHg-MEAN - AVG.csv"

	cat "$src_file" | awk -F"," '{ split($1,a,".") ; print 86400*(($1-a[1])+(a[1]-25569))-v","$2}' v="${p_epoch_start_time}" > $dst_file
done

# Prepare Monitr_NBP
nbp_files=`ls $NBP_DIR`
for NBP_file in $nbp_files ; do
	# check if patient record exist
	id=`echo $NBP_file | cut -d"-" -f2 | cut -d"." -f1`
        PATIENT_FILE=$LOG_RES_DIR/$id.csv
	[ ! -f  $PATIENT_FILE ] && { echo $message $NBP_DIR/$NBP_file >> $ERRORS_FILE; continue; }
	p_epoch_start_time=`cat $PATIENT_FILE`

	src_file=$NBP_DIR/$NBP_file
	dst_file=$NBP_RES_DIR/$NBP_file

	cat "$src_file" | awk -F "," '{a=gensub(/[/:]/," ","g",$1) ; split(a, b, " "); c=b[3]" "b[2]" "b[1]" "b[4]" "b[5]" 0"; print mktime(c)-v","$2}' v="${p_epoch_start_time}" > $dst_file
done

# prepare Record_sheet-I
rec_i_files=`ls $RECORD_SHEET_I_DIR`
for REC_file in $rec_i_files; do

	# check if Patient's info record exist
	#id=`echo $REC_file | sed 's/[a-z,.]//g' | sed 's/^0*//'`
	id=`echo $REC_file | cut -d"." -f1`
        PATIENT_FILE=$LOG_RES_DIR/$id.csv
	[ ! -f  $PATIENT_FILE ] && { echo $message $RECORD_SHEET_I_DIR/$REC_file >> $ERRORS_FILE; continue; }
	p_epoch_start_time=`cat $PATIENT_FILE`

	src_file=$RECORD_SHEET_I_DIR/$REC_file
	dst_file=$RECORD_SHEET_I_RES_DIR/$REC_file

	cat "$src_file" |  awk -F"," 'NR==1{} NR>1{a=gensub(/[/:]/," ","g",$2) ; split(a, b, " "); split($4,c,":"); d=b[3]" "b[2]" "b[1]" "c[1]" "c[2]" 0"; print mktime(d)-v","$(NF-1)}' v="${p_epoch_start_time}" > $dst_file
done

exit 0
