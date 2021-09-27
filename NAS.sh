#!/bin/bash

clear
which figlet &>> /dev/null
if [ $? -eq 0 ]
then 
    figlet NAS Automation 
    echo -e "   By:\t\tShrit Shah\tHarshil Shah\tNisarg Khacharia"
else
    echo -e "\v\v \t\t\t\t NAS AUTOMATION \n"
fi


new_setup()
{
    echo -e "\vWhere do you want to setup your storage server? \n\n\t1) Another system on the same LAN. \n\t2) In a cloud virtual machine."
    read -p "--> " server_location

    if [ $server_location -eq 1 ]
    then
        ansible_install
        client_ip=$(hostname -I | awk {'print $1}') # Client Private IP-address
        read -p "Enter private ip-address of the server system: " server_ip
        
        # IP validation - REGEX: ((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}

        echo -e "\nEstablishing connection to $server_ip ... \n"

        ping -c 3 $server_ip &>> /dev/null
        if [ $? -eq 0 ]
        then 
            echo -e "Connection Successful\n"

            read -p "Enter Server username: " user_name
            read -p "Enter ${usr_name}'s password" user_pass

            ansible_setup ${server_ip} ${user_name} ${user_pass}

            #scp server.sh  ${usr_name}@${server_ip}:/tmp/ &>> /dev/null

            read -p "Name the backup folder on the Server: " server_dir

            ansible-playbook nas-playbook.yml -e "client_ip=${client_ip} server_user_name=${user_name} server_bak_dir=${server_dir}" &>> /dev/null
            echo -e "\n Name and location of Backup folder on server with ip-->(${server_ip}) is '\033[1m\NASbackup'\033[0m'\n"

            if [ $? -eq 0 ]
			then
			
				echo -e "\n Server configuration successfull. \033[1m(${server_ip})\033[0m node is now configured as \033[4mNAS Backup Server\033[0m\n"
				echo -e "Name and location of Backup folder on server with ip-->(${server_ip}) is '\033[1m\${server_dir}'\033[0m'\n"
				echo -e "Now for configuring client...\n\n"
				
				read -p "Name the backup folder here on the Client: " client_dir
				
				mkdir ${HOME}/Desktop/${client_dir} &>> /dev/null
				sudo mount  ${server_ip}:/home/${user_name}/Desktop/${server_dir}  ${HOME}/Desktop/${client_dir} &>> /dev/null #Mounting directories
				
				
				if [ -d ${HOME}/Desktop/${client_dir} -a $? -eq 0 ]
				then 
					
					echo "Setup on both client and server SUCCESSFULL" 
				else 
					echo "Setup configuration on client side FAILED"
					
				fi		
			
			fi
			
		else
			echo "Connection Failed"
		fi


#Remove after examining-----------------------------------------------------------------------------------------------------------------------------
<< comment
            if [ $? -eq 0 ]
            then
                echo -e "\nSSH connection successful\n"
                
                read -p "Name of backup folder on the Server: " server_bak_dir
                cmd=$(echo sudo -S -p "Enter\ sudo\ password\ of\ server-side: " bash /tmp/server.sh ${usr_name} ${server_bak_dir} ${client_ip})
                echo "\nConfiguring NAS server on $server_ip ...\n"
                ssh ${usr_name}@${server_ip} $cmd
                if [ $? -eq 0 ]
                then   
                    echo -e "\nServer configuration successful\n"
                    read -p "Name of backup folder here on the Client: " client_dir
                    mkdir ${HOME}/Desktop/${client_dir}
                    
                    sudo mount  ${server_ip}:/home/${usr_name}/Desktop/${server_bak_dir}  ${HOME}/Desktop/${client_dir} #Mounting directories
                    if [ $? -eq 0 ]
                    then    
                        echo -e "\v\tSetup Successful"
                        exit
                    fi
                else
                    echo "Server configuration failed"
                fi
            else
                echo -e "SSH connection failed\nPlease run the below commands manually on the server system & run this script again."
                echo -e "\v\tsudo yum -y install openssh \n\tsudo systemctl enable --now sshd"
            fi
        else
            echo "Connection Failed"
        fi
comment
#Remove after examining-----------------------------------------------------------------------------------------------------------------------------

    elif [ $server_location -eq 2 ]
    then
        echo "Coming Soon!!"
        #$client_ip=$(dig +short myip.opendns.com @resolver1.opendns.com) # Client Public IP-address
    
    else
        echo -e "\vInvalid Input"
    fi


}

modify_setup()
{
    echo "Coming Soon!!"
}

uninstall()
{
    echo "Coming Soon!!"
}

ansible_install()
{
    #installing ansible on client machine

    pip3 show ansible >> /dev/null
    if [ $? -eq 1 ]
    then
	    pip3 install ansible >> /dev/null
	    pip3 show ansible >> /dev/null
	    if [ $? -eq 0 ]
	    then
		    echo "\n\tAnsible is installed in your system for server side configuration\n"
        fi
    fi
}

ansible_setup()
{
    #configuring inventory file for ansible

    server_ip = $1
    usr_name = $2
    usr_pass = $3
    connection_type = ssh
    #[ -f /root/.NAS/.ip.txt ]
    if [ -f /root/.NAS/.ip.txt ]
    then
	    mkdir /root/.NAS
	    echo "[NASserver]" > /root/.NAS/.ip.txt

    else
	    echo "${server_ip} ansible_user=${usr_name} ansible_password=${usr_pass} ansible_connection=${connection_type}" >> /root/.NAS/.ip.txt
    fi

    #configuring ansible.cfg file

   #[ -d /etc/ansible/ ]
    if [ -d /etc/ansible/ ]
    then
	    mkdir /etc/ansible/
	    echo -e "[defaults]\ninventory = /root/.NAS/.ip.txt\nhost_key_checking = False\ndeprecation_warnings = False\ncommand_warnings = False" > /etc/ansible/ansible.cfg
    fi
}

while [ 0 ]
do
    echo "-----------------------------------------------------------------------------"
    echo -e "\v\t1) Setup new storage \n\t2) Modify existing configuration \n\t3) Remove all NAS connections \n\t00) Exit" #Main Menu

    read -p "--> " menu_opt

    case $menu_opt in 
        1) 
            new_setup
            ;;
        2) 
            modify_setup
            ;;
        3) 
            uninstall
            ;;
        00) 
            echo "Exiting"
            break
            ;;
        *)
            echo "Select valid option from the menu"
            ;;
    esac
done

exit 0 &>> /dev/null