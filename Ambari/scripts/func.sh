function print_time_tag() {
  date +"%Y%m%d_%H%M"
}

function mail_tool() {
  MAIL_TITAL_TAIL="$1"
  if [ -z "$2" ]
  then
    M_CONTENT="."
  else
    M_CONTENT="$2"
  fi
  sh $MAIL_TOOL -t $ADMIN_MAIL -s "$MAIL_TITAL $MAIL_TITAL_TAIL" -c "$M_CONTENT" > /dev/null
  rm -f temp_wget_mail
}

function check_value_add() {
  if [ $? -ne 0 ]
  then
    CHECK_TAG=$1
    CHECK_TAG=$((CHECK_TAG+1))
  fi
}

function postgre_dump() {
  export PGPASSWORD=$1
  PG_USER=$2
  PG_DATABASE=$3
  local BACKUP_SQL="$TMP_DIR/${BACKUP_FILE_TAG}_$PG_DATABASE.sql"
  $PG_DUMP -U $PG_USER $PG_DATABASE > "$BACKUP_SQL"
  check_value_add $CHECK_TAG
}
