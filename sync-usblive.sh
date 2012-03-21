#! /bin/bash

######################################################################################
# Script de gestion de connexion et sauvegarde du /home de la clef sur le poste fixe #
######################################################################################


#------------------------------------------------------------------------------------#
# Fonction pour la barre de progression
#------------------------------------------------------------------------------------#

afficheTaille () {

taille=$(sed '/\./! s/^.*$/&.00/' <<< $1)
i=1
while [[ ${#taille} -ge 7 ]]; do
	taille=$(bc <<< "scale=2;$taille/1024")
	((i =1))
done
case $i in
	1) taille =" octets" ;;
	2) taille =" Ko" ;;
	3) taille =" Mo" ;;
	4) taille =" Go" ;;
esac
echo $taille
}

#-------------------------------------------------------------------------------------#
# Déclaration des variables
#-------------------------------------------------------------------------------------#

# Paramètres d'identification de la clef
DEVTYPE="usb"
ID_SERIAL_SHORT="A500000000026452"
KEY_SYNC=/dev/LiveUSB2
USERNAME="leseb" # Indispensable pour l'affichage des fenêtres Zenity

# Répertoire destination, de montage de LiveUSB2, du montage du volume crypté,de l'emplacement du home crypté, de backup du .img
DEST_DIR=/home/leseb/udevsync/
MONT_POINT=/home/leseb/MOUNT/
CRYPT_MOUNT=/home/leseb/CRYPT/
CONTENEUR=/home/leseb/MOUNT/luks-home.img
BKP_CONT=/home/leseb/Backup_IMG/

# Fichiers de log horodatés
BKP_DATE=`date +"%Y-%m-%d_%H-%M"`
LOG_FILE=/tmp/Logs_Sync/sdBackup_${BKP_DATE}.log
RSYNC_ERR=/tmp/rsync.err

#------------------------------------------------------------------------------------#
# Algo
#------------------------------------------------------------------------------------#

# Initialisation du fichier de log
echo "Backup du $BKP_DATE" > $LOG_FILE
echo "Début à `date '%H:%M:%S'`" >> $LOG_FILE

# Action à l'insertion de la clef
if [ "$ID_FS_TYPE" = "ext2" ] ; then # Variable de UDev pour l'insertion de clef
	# Montage de la partition contenant le volume crypté
	mount $KEY_SYNC $MONT_POINT
	# Demande de synchronisation
	su - ${USERNAME} -c "DISPLAY=:0.0 zenity --question --title='Bienvenue' --text='Clef montée. \nVoulez-vous synchroniser le <b>/home</b> de la clef ?'"
	if [ "$?" = 0 ]; then # Si on clique sur "Valider"
		if [ -f $CONTENEUR ] ; then # vérifie si le volume crypté existe
			# Cherche un loop libre
			loop=$(losetup -f)
			/sbin/losetup $loop $CONTENEUR
			# Ouverture du conteneur et saisie de mot de passe
			mdp=$(su - ${USERNAME} -c "DISPLAY=:0.0 zenity --entry \
			--title='Ouverture du conteneur chiffré' \
			--text='Entrez le mot de passe pour ouvrir le volume chiffré' \
			--hide-text")
			# On envoie le mot de passe dans la commande
			echo $mdp|/sbin/cryptsetup luksOpen $loop LUKS
			# On monte le contenu du volume chiffré dans un dossier
			mount -o loop /dev/mapper/LUKS $CRYPT_MOUNT
			# Synchronisation avec barre de progression
			echo "0" > nb
			DEBUT=$(date %s)
			rsync -av --delete --update --perms --owner --ignore-errors --force --progress $CRYPT_MOUNT/ $DEST_DIR/ 2>>$RSYNC_ERR | sed '
			/to-check=/! {
			/^sending/ {d;q;}
			/\/$/
			{d;q;}
			/^sent/
			{s/^.*$/echo "&" \>\/tmp\/rapport\.txt/e;d;q;};
			/^total/ {s/^.*$/echo "&" \>\>\/tmp\/rapport\.txt/e;d;q;};
			/^.\{43\}/ {s/\(^.\{20\}\).*\(.\{20\}$\)/echo \$\(\(\$\(cat nb\) 1\)\) \> nb; echo "\1\[...\]\2" \>\/tmp\/svgrd_sed\.txt/e;d;q;};
			/^.\{43\}/! {s/^.*$/echo \$\(\(\$\(cat nb\) 1\)\) \> nb; echo "&" \>\/tmp\/svgrd_sed\.txt/e;d;q;};
			}
			/to-check=/ {
			s/.*=\(.*\)\/\(.*\))/echo "#`echo "scale=2;\(\2-\1\)\*100\/\2" | bc | cut -d\. -f1`% (\$\(\(\2 - \1\)\) fichiers sur \2\) > \$\(cat \/tmp\/svgrd_sed\.txt\)"\; echo "scale=2;\(\2-\1\)\*100\/\2" | bc/e
			}
			' | su - ${USERNAME} -c "DISPLAY=:0.0 zenity --progress --width=580 --title='Synchronisation' --text='Initialisation de la sauvegarde...' --percentage=0 --auto-close"
			FIN=$(date %s)
			TEMPS=$(($FIN-$DEBUT))
			TP_HEU=$(sed 's/^.$/0&/' <<< $(($TEMPS/3600)))
			TP_TMP=$(($TEMPS%3600))
			TP_MIN=$(sed 's/^.$/0&/' <<< $(($TP_TMP/60)))
			TP_SEC=$(sed 's/^.$/0&/' <<< $(($TP_TMP%60)))
			TP=$(echo "$TP_HEU:$TP_MIN:$TP_SEC")
			# Vérifie la sortie de rsync
			ERR=$(cat $RSYNC_ERR)
			ERR=$(cat $RSYNC_ERR)
			if [[ ${#ERR} -ne 0 ]]; then
				su - ${USERNAME} -c "DISPLAY=:0.0 zenity --error --title='Erreur de copie' --text='Problème lors de la sauvegarde du répertoire <b>$MOUNT_POINT</b>.\n\n<b><span color='red'>$ERR</span></b>.'"
				rm $RSYNC_ERR
			else
				NB_FICH=$(cat nb)
				ENVOI=$(afficheTaille $(cat /tmp/rapport.txt | grep sent | cut -d' ' -f2))
				VITESS=$(afficheTaille $(cat /tmp/rapport.txt | grep sent | cut -d' ' -f9))
				su - ${USERNAME} -c "DISPLAY=:0.0 zenity --info --title='Terminé' --text='Sauvegarde du répertoire\n<b>$CRYPT_MOUNT</b> effectuée avec succès.\n$NB_FICH fichiers synchronisés\nTemps:\t$TP\nTransfert:\t$V"
				rm nb
			fi

			# Précaution de backup du volume chiffré
			cp $CONTENEUR $BKP_CONT
			su - ${USERNAME} -c "DISPLAY=:0.0 zenity --info --title='Backup' --text='Le backup du luks-home.img a été effectué'"
		else
			su - ${USERNAME} -c "DISPLAY=:0.0 zenity --error \
			--title='Erreur' \
			--text='Aucun volume crypté trouvé !'"
		fi
	fi
fi

if [ "$ACTION" = "remove" ] ; then # Variable de UDev
	# Démonter le volume crypté
	umount $CRYPT_MOUNT
	# Fermer le volume crypté
	/sbin/cryptsetup luksClose LUKS
	# Libérer le loop
	/sbin/losetup -d $loop
	# Démontage de la clef
	umount -f $KEY_SYNC >> $LOG_FILE
	su - ${USERNAME} -c "DISPLAY=:0.0 zenity --info --title='Au revoir' --text='Clef démontée avec succès.'"
fi
#------------------------------------------------------------------------------------#
# EOF
#------------------------------------------------------------------------------------#

