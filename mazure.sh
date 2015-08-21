#!/bin/bash
#SHELL SCRIPT FOR EDITING AZURE
#WRITTEN BY MIKE THOMA
#IN AN ATTEMPT TO MAKE AZURE BETTER
rc=$?
AZNAME="24c06b81-65c8-4def-a4ca-e34ec04b3112"
REGLIST=files/regions
STYPES=files/types
SIZES=files/sizes
IMGFILE=files/EASTUScentos66.vhd
PUBKEY=files/id_rsa.pub

#-----------------------------------
# MAIN FUNCTIONS
#-----------------------------------

#RUNS FIRST TO MAKE SURE ACCOUNT SETUP AND IN ASM MODE
azure config mode asm
account_setup() {
	azure account set "$AZNAME"
		if [ $? != 0 ];
		then
		echo "ACCOUNT SETUP FAILED"
		echo "CONTACT ADMIN TO CONNECT TO ACCOUNT"
		exit 1
	fi
}

#RUNS EACH TIME TO SET UP ACCOUNT KEYS
storage_setup() {

	clear
	azure storage account list
	echo "**"
	echo "Enter Storage Account Name"
	read AZURE_STORAGE_ACCOUNT
        export AZURE_STORAGE_ACCOUNT=$AZURE_STORAGE_ACCOUNT
        azure storage account set $AZURE_STORAGE_ACCOUNT
        KEY=$(azure storage account keys list "$AZURE_STORAGE_ACCOUNT" | grep "Primary" | awk '{print $3}')
        export AZURE_STORAGE_ACCESS_KEY=$KEY
	if [ -z $KEY ];
	then
		echo "STORAGE ACCOUNT DOES NOT EXIST!"
		echo "EXITING"
		exit 2
	fi

}

get_region() {
	clear
	cat $REGLIST
	echo ""
	echo $MSG
	echo "Pick a number: "
	read CHOICE
	REG=$(grep -m 1 "$CHOICE" $REGLIST | sed 's/.*://g' | sed 's/^/"/;s/$/"/')
}

get_stype() {

	clear
	cat $STYPES
	echo ""
	echo "Pick a number:"
	read CHOICE
	STYPE=$(grep -F "$CHOICE" $STYPES | sed 's/.*://g')

}


get_cont() {

	clear
	echo "STORAGE ACCOUNT: "$AZURE_STORAGE_ACCOUNT""
	echo ""
        azure storage container list
        echo "**"
        echo "Enter the container"
        read CONT

}

create_storage() {

	clear
	echo "Enter a name to use for storage" 
	read AZURE_STORAGE_ACCOUNT
	get_stype
	get_region
	echo ""
	echo "CREATING $AZURE_STORAGE_ACCOUNT TYPE $STYPE IN $REG.... "
	sleep 3
	echo "azure storage account create --type $STYPE --location $REG $AZURE_STORAGE_ACCOUNT" > /tmp/op.sh
	chmod +x /tmp/op.sh | /tmp/op.sh
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "PUSH ENTER TO RETURN TO MAIN MENU"
	read A

}

delete_storage() {

	clear
	echo "****************"
	echo "DELETE STORAGE ACCOUNT"
	echo "****************"
	storage_setup
	azure storage account delete $AZURE_STORAGE_ACCOUNT
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}

create_container() {

	clear
	echo "****************"
	echo "CREATE CONTAINER"
	echo "****************"
	storage_setup
	echo ""
	echo "Enter a name for the new container in: "
	read CONT
	azure storage container create $CONT
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "PUSH ENTER TO RETURN TO MAIN MENU"
	read A

}

delete_container() {

        clear
        echo "****************"
        echo "DELETE CONTAINER"
        echo "****************"
        storage_setup
	clear
	echo ""
	get_cont
        azure storage container delete $CONT
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}

upload_image() {

        echo "****************"
        echo "UPLOAD IMAGE"
        echo "****************"
	echo "NAME YOUR IMAGE"	
	read IMG
	storage_setup
	get_cont
	get_region
	echo "azure vm image create $IMG -f --blob-url https://"$AZURE_STORAGE_ACCOUNT".blob.core.windows.net/"$CONT"/"$IMG" --location $REG --os Linux $IMGFILE" > /tmp/op.sh
	chmod +x /tmp/op.sh | /tmp/op.sh
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}

upload_blob() {

	storage_setup
	get_cont
	clear	
	echo "Provide full path for file to upload in "$AZURE_STORAGE_ACCOUNT" container "$CONT""
	read BLOB
	azure storage blob upload $BLOB $CONT
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}

download_blob() {

	storage_setup
	get_cont
	clear
	echo "Enter a location path to save blob"
	read BPATH
	azure storage blob list $CONT
	echo ""
	echo "Enter a blob to download"
	read BLOB
	azure storage blob download $CONT $BLOB $BPATH	
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}

delete_blob() {

	storage_setup
	get_cont
	azure storage blob list $CONT
	echo "Enter a blob to delete"
	read BLOB
	azure storage blob delete $CONT $BLOB
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}

deploy_vm(){

	clear
	echo "***************"
	echo "DEPLOY VM"
	echo "***************"
	echo "Enter name for the VM"
	read VMNAME
	get_region
	clear
	storage_setup
	get_cont
	clear
	echo "Enter DNS name for machine"
	read DNS
	echo ""
	echo "enter VM size"
	read SIZE
	echo ""
	echo "enter ssh port"
	read PORT
	IMG=CENTOSSYKES
	echo ""
	echo "Enter username"
	read USER
	echo "azure vm create --subscription $AZNAME --blob-url https://"$AZURE_STORAGE_ACCOUNT".blob.core.windows.net/"$CONT"/"$VMNAME" --location $REG --ssh $PORT --ssh-cert id_rsa.pub --no-ssh-password --vm-size $SIZE --vm-name $VMNAME $DNS $IMG $USER" > /tmp/op.sh
	chmod +x /tmp/op.sh ; /tmp/op.sh
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "PUSH ENTER TO RETURN TO MAIN MENU"
        read A

}



account_setup
#-----------------------------------
# MENU SELECTIONS
#-----------------------------------

amenu="a. Create Storage Account"
bmenu="b. Delete Storage Account"
cmenu="c. Create Container"
dmenu="d. Delete Container"
hmenu="e. Upload an image"
emenu="f. Upload a blob "
fmenu="g. Download a blob"
gmenu="h. Delete a blob"
imenu="i. Deploy VM To Storage Account"

#-----------------------------------
# MENU FUNCTIONS
#-----------------------------------


badchoice () { MSG="I'm sorry, Dave... I'm afraid I can't do that." ; }

aopt () { create_storage;   }
bopt () { delete_storage;   }
copt () { create_container; }
dopt () { delete_container; }
eopt () { upload_image ;    }
fopt () { upload_blob ;    }
gopt () { download_blob ;    }
hopt () { delete_blob ;    }
iopt () { deploy_vm ;       }

#-----------------------------------
# DISPLAY FUNCTION
#-----------------------------------

HEADER="~AZURE DEPLOYMENT SCREEN~"
themenu () {
  clear
  echo
  echo
  echo -e '\t\t\t' "$HEADER"
  echo
  echo
  echo -e '\t\t' "-----------------------"
  echo -e '\t\t' "STORAGE ACCOUNT OPTIONS"
  echo -e '\t\t' "-----------------------"
  echo -e '\t\t' "$amenu"
  echo -e '\t\t' "$bmenu"
  echo -e '\t\t' "$cmenu"
  echo -e '\t\t' "$dmenu"
  echo ""
  echo -e '\t\t' "-----------------------"
  echo -e '\t\t' "BLOB MENU"
  echo -e '\t\t' "-----------------------"
  echo -e '\t\t' "$emenu"
  echo -e '\t\t' "$fmenu"
  echo -e '\t\t' "$gmenu"
  echo ""
  echo -e '\t\t' "-----------------------"
  echo -e '\t\t' "VM OPTIONS"
  echo -e '\t\t' "-----------------------"
  echo -e '\t\t' "$hmenu"
  echo -e '\t\t' "$imenu"
  echo ""
  echo ""
  echo -e '\t\t' "q. Exit"
  echo
  echo $MSG
  echo
  echo Select an option and press ENTER ;
}

#-----------------------------------
# MENU LOGIC
#-----------------------------------

MSG=

while true
do
    themenu
    read answer
    MSG=

    case $answer in
      a|A) aopt;;
      b|B) bopt;;
      c|C) copt;;
      d|D) dopt;;
      e|E) eopt;;
      f|F) fopt;;
      g|G) gopt;;
      h|H) hopt;;
      i|I) iopt;;
      q|Q) break;;
      *)badchoice;;
    esac
done
