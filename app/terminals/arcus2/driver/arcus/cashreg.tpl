#port section
SPEED=115200
BYTE=8
PARITY=N
STOP=1
#to in miliseconds
TIMEOUT=50
PPAD_IDLE_TO=120000

NO_PA_DSS
#NODIALOGS

OPERATION_INI_FILE=ops.ini
#OPERATION_INI_FILE=ops_spdh.ini

RC_CONVERT_FILE=rc_conv.ini

#files section
CHEQ_FILE=cpd.out
RESULT_FILE=rc.out

#auto cancel operation
CANCEL_CH_FILE=auto_can.out
CANCEL_RC_FILE=can_rc.out

#Comment to enable PPAD Date and time Syncronisation

#NOTIMESYNC
#USEAPPLOG
#USEPPADTRACE

#response code converting
RC_CONVERT_FILE=rc_conv.ini

#response code resolver
RC_RESOLVE_FILE=rc_res.ini
DEFAULT_RC_STRING=Нет кода ответа
USEORIGINALRC

USE_PRINTER=NONE
INPUT_FILE=chek.in
OUTPUT_FILE=chek.out

#Operating Charset only 1251
PPCHARSET=CP1251
#Output char se
#OPCHARSET=KOI8-r
OPCHARSET=cp866
