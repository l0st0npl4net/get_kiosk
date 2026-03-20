#!/bin/bash

export RESPONSE_FILE_NAME=RESPONSE.txt
export RECORD_FILE_NAME=RECORD.TXT
export IS_ONLINE="true"
export RECEIPT_NUMBER=106
export PAYMENT_AMOUNT=1257
export ARCUS_CHEQ_CNT=1


echo "============ONE SLIP TEST========" >> printer.txt
./cpd.sh -authorize
./cpd.sh -parse
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -commit



echo "============Cancel after commit========" >> printer.txt
./cpd.sh -cancel


export RECEIPT_NUMBER=107
export PAYMENT_AMOUNT=1258
export ARCUS_CHEQ_CNT=2

echo "============TWO SLIPS TEST========" >> printer.txt
./cpd.sh -authorize
./cpd.sh -parse
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -commit

export RECEIPT_NUMBER=109
export PAYMENT_AMOUNT=1259

echo "============CANSEL TEST========" >> printer.txt
./cpd.sh -authorize
./cpd.sh -cancel


export RECEIPT_NUMBER=110
export PAYMENT_AMOUNT=1260

echo "============EMERGENCY CANCEL TEST========" >> printer.txt
./cpd.sh -authorize
./cpd.sh -parse

export RECEIPT_NUMBER=111
export PAYMENT_AMOUNT=1261

./cpd.sh -authorize
./cpd.sh -parse
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -commit


export RECEIPT_NUMBER=112
export PAYMENT_AMOUNT=1262

echo "============MULTI PAYMENT TEST========" >> printer.txt
./cpd.sh -authorize
./cpd.sh -parse


export PAYMENT_AMOUNT=1263

./cpd.sh -authorize
./cpd.sh -parse


export PAYMENT_AMOUNT=1264

./cpd.sh -authorize
./cpd.sh -parse
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -commit


echo "============EMERGENCY MULTI PAYMENT CANCEL TEST========" >> printer.txt
export RECEIPT_NUMBER=113
export PAYMENT_AMOUNT=1265

./cpd.sh -authorize
./cpd.sh -parse

export PAYMENT_AMOUNT=1266

./cpd.sh -authorize
./cpd.sh -parse

export RECEIPT_NUMBER=114
export PAYMENT_AMOUNT=1264

./cpd.sh -authorize
./cpd.sh -parse
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -slip
cat cheq.out >> printer.txt
./cpd.sh -commit


echo "============FULL REPORT TEST========" >> printer.txt
./cpd.sh -report
cat cheq.out >> printer.txt

echo "============SHORT  REPORT TEST========" >> printer.txt
./cpd.sh -reportshort
cat cheq.out >> printer.txt

echo "============EOD  REPORT TEST========" >> printer.txt
./cpd.sh -eod
cat cheq.out >> printer.txt



