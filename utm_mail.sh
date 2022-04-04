#!/bin/bash
# Return Codes:
# 0 - Ok!       - Up
# 1 - Warning   - Flaky
# 2 - Critical  - Down
# 3 - Unknown   - Ummm... What happened?!


#Funktionen
function showUsage {
  echo "
  Benutzung: $0 [Parameter]
  -h  Hostname / IP-Adresse
  -K  Pfad zum privaten RSA-Schlüssel
  -u  SSH-Nutzer
  -p  SSH-Port
  -M  Modus
      'quarantine'      => wertet Mails in Quarantäne aus
      'output'          => wertet ausgehende Mails aus
      'corrupt'         => wertet koruppte Mail aus
  "
}

while [ "$1" != "" ]; do
  case "$1" in
    -h) shift; strHost="$1";;
    -K) shift; strKeyPath="$1";;
    -u) shift; strSSHUser="$1";;
    -p) shift; intSSHPort="$1";;
    -M) shift; strModus="$1";;
    *) showUsage; exit 3;;
  esac
  shift
done

if [ -z $strHost ] || [ -z $strKeyPath ] || [ -z $intSSHPort ] || [ -z $strModus ] ; then
  showUsage
  exit 1
fi

if [ -z $strSSHUser ] ; then
  strSSHUser="loginuser"
fi

if [ "x$strModus" == "xquarantine" ] ; then
  intErgebnis=$(ssh -i $strKeyPath ${strSSHUser}@${strHost} -p $intSSHPort "find /var/storage/chroot-smtp/spool/quarantine -type f | wc -l")
  if [ $? -ne 0 ] ; then
    echo "Fehler beim Abrufen der Daten"
    exit 3
  fi

  if [ $intErgebnis -le 1 ] ; then
    echo "OK: Keine Mails in Quarantäne"
    exit 0
  elif [ $intErgebnis -gt 1 ] ; then
    intMails=$(echo "(${intErgebnis} -1) / 2" | bc)
    echo "CRITICAL: Es befinden sich $intMails Mails in Quarantäne"
    exit 2
  fi
fi

if [ "x$strModus" == "xoutput" ] ; then
  intErgebnis=$(ssh -i $strKeyPath ${strSSHUser}@${strHost} -p $intSSHPort "find /var/storage/chroot-smtp/spool/output -type f | wc -l")
  if [ $? -ne 0 ] ; then
    echo "Fehler beim Abrufen der Daten"
    exit 3
  fi

  if [ $intErgebnis -le 1 ] ; then
    echo "OK: Keine Mails in der Ausgangswarteschlange"
    exit 0
  elif [ $intErgebnis -gt 1 ] ; then
    intMails=$(echo "(${intErgebnis} -1) / 2" | bc)
    echo "CRITICAL: Es befinden sich $intMails Mails in der Ausgangswarteschlange"
    exit 2
  fi
fi

if [ "x$strModus" == "xcorrupt" ] ; then
  intErgebnis=$(ssh -i $strKeyPath ${strSSHUser}@${strHost} -p $intSSHPort "find /var/storage/chroot-smtp/spool/corrupt -type f | wc -l")
  if [ $? -ne 0 ] ; then
    echo "Fehler beim Abrufen der Daten"
    exit 3
  fi

  if [ $intErgebnis -le 1 ] ; then
    echo "OK: Keine korrupten Mails"
    exit 0
  elif [ $intErgebnis -gt 1 ] ; then
    intMails=$(echo "(${intErgebnis} -1) / 2" | bc)
    echo "CRITICAL: Es $intMails korrupte Mails vorhanden"
    exit 2
  fi
fi

echo "Unbekannter Status"
exit 3
