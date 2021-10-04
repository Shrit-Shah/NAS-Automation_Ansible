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

    #if [ $server_location -eq "1" ]    ERROR: If none selected than error of "unary operator expected" comes at line 20 and 175
    #then

    case $server_location in 

        1)
            

            ############################ Inastalling ansible and calling spin2 function #############################

            #echo -e "\nInstalling ansible for server side configuration"
            spin2 "Installing ansible-4.6.0  " &
            pid=$!
            ansible_install
            echo -e "\n"
            kill $pid 2>&1 >> /dev/null
            #echo -e "\n"
            tput cnorm
            echo ""

            ##########################################################################################################


            # reading Client Private IP-address from client machine and taking server private IP address from user

            client_ip=$(hostname -I | awk {'print $1}')
            read -p "Enter private ip-address of the server system: " server_ip

            
            # IP validation - REGEX: ((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}


            ################ Running ping command to check connectivity between server and client ######################

            #echo -e "\nEstablishing connection to $server_ip "
            spin2 "Establishing Connection to $server_ip  "  &    #adding loading animation to above echo line
            pid=$!
            ping -c 5 $server_ip &>> /dev/null
            ping_process=$?   #Storing return code of above command in ping_process variable
            echo -e "\n"
            kill $pid 2>&1 >> /dev/null
            tput cnorm
            echo ""

            ############################################################################################################


            if [ $ping_process -eq 0 ]
            then 
                echo -e "Connection Successful\n"

                # Asking user for server's user name
                read -p "Enter Server username: " user_name   
                echo -e "\n\033[3mPassword you type will not be visible on screen but will be recorded\033[0m\n"
                # Asking user for server's password
                read  -s -p "Enter ${user_name}'s password: " user_pass
                #echo -e "\n"

                
                ########################## Configuration of ansible on client machine ###################################

                #echo -e "\nConfiguring ansible and setting up neccessary config files"
                echo -e "\nCollecting server --> ${user_name}'s HOME directory path!!!"
                sshpass -p "${user_pass}" ssh ${user_name}@${server_ip} echo $HOME > /tmp/temp.txt
                server_home_dir=$(cat /tmp/temp.txt)

                #spin2 "Configuring ansible and setting up neccessary config files  "  &
                #pid=$!
                ansible_setup ${server_ip} ${user_name} ${user_pass} ${server_home_dir}
                if [ $? -eq 3 ]
                then
                    echo -e "\n"
                    #kill $pid 2>&1 >> /dev/null
                    #tput cnorm
                    #echo ""
                elif [ $? -eq 1 ]
                then
                    #kill $pid 2>&1 >> /dev/null
                    exit
                fi

                #########################################################################################################



                #scp server.sh  ${usr_name}@${server_ip}:/tmp/ &>> /dev/null
                #echo -e "\n"
                read -p "Name the backup folder on the Server: " server_dir  # Asking user to type in server side backup folder's name


                ########################## Configuring NAS server in server machine by executing ansible playbook ##########################

                #echo -e "\nConfiguring NAS server. Running ansible playbook"
                echo -e "\nHome directory of ${server_ip} is '${server_home_dir}'"


                #echo -e "${server_home_dir}/Desktop/${server_dir} *(rw,no_root_squash)" > ${server_home_dir}/Desktop/.NAS/exports.j2
                spin2  "Configuring NAS server. Running ansible playbook  "  &
                pid=$!
                ansible-playbook nas-playbook.yml --extra-vars "home=${server_home_dir} server_bak_dir=${server_dir}" >> /dev/null
                play_process=$?
                echo -e "\n"
                kill $pid 2>&1 >> /dev/null
                tput cnorm
                echo ""

                #############################################################################################################################



                if [ $play_process -eq 0 ]
                then
                
                    echo -e "\n Server configuration successfull. \033[1m(${server_ip})\033[0m node is now configured as \033[4mNAS Backup Server\033[0m\n"
                    echo -e "Name and location of Backup folder on server with ip-->(${server_ip}) is '\033[1m/home/${user_name}/Desktop/${server_dir}/\033[0m'\n"
                    echo -e "Now for configuring client...\n\n"
                    
                    read -p "Name the backup folder here on the Client: " client_dir  # Asking user to type in client side backup folder's name that will be mounted on server
                    
                    mkdir /${HOME}/Desktop/${client_dir} &>> /dev/null
                    sudo mount  ${server_ip}:${server_home_dir}/Desktop/${server_dir}  /${HOME}/Desktop/${client_dir} &>> /dev/null #Mounting directories
                    
                    
                    if [ -d /${client_dir} -a $? -eq 0 ]
                    then 
                        
                        echo "Setup on both client and server \033[1mSUCCESSFULL\033[0m\n\n"
                        echo -e "Name and location of Backup folder on your client machine having ip-->(${client_ip}) and Username-->${user_name} is '\033[1m${HOME}/Desktop/${client_dir}\033[0m'\n" 
                    else 
                        echo "Setup configuration on client side FAILED"
                        
                    fi
                else
                    echo "Server Configuration failed, playbook didn't executed"	
                
                fi
                
            else
                echo "Connection Failed"
            
            fi
            
            ;;


#Remove after examining-----------------------------------------------------------------------------------------------------------------------------
#                if [ $? -eq 0 ]
#                then
#                    echo -e "\nSSH connection successful\n"
#                    
#                    read -p "Name of backup folder on the Server: " server_bak_dir
#                    cmd=$(echo sudo -S -p "Enter\ sudo\ password\ of\ server-side: " bash /tmp/server.sh ${usr_name} ${server_bak_dir} ${client_ip})
#                    echo "\nConfiguring NAS server on $server_ip ...\n"
#                    ssh ${usr_name}@${server_ip} $cmd
#                    if [ $? -eq 0 ]
#                    then   
#                        echo -e "\nServer configuration successful\n"
#                        read -p "Name of backup folder here on the Client: " client_dir
#                        mkdir ${HOME}/Desktop/${client_dir}
#                        
#                        if [ $? -eq 0 ]
#                        then    
#                            echo -e "\v\tSetup Successful"
#                            exit
#                        fi
#                    else
#                        echo "Server configuration failed"
#                    fi
#                else
#                    echo -e "SSH connection failed\nPlease run the below commands manually on the server system & run this script again."
#                    echo -e "\v\tsudo yum -y install openssh \n\tsudo systemctl enable --now sshd"
#                fi
#Remove after examining-----------------------------------------------------------------------------------------------------------------------------



    #elif [ $server_location -eq "2" ]
    #then

        2)
            echo "Coming Soon!!"
            #$client_ip=$(dig +short myip.opendns.com @resolver1.opendns.com) # Client Public IP-address
            ;;
        

        *)
            echo -e "\vSelect valid option from the menu"
            ;;

    esac
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

    ansible_version="ansible 2.10.14"
    pip3 show ansible >> /dev/null

    if [ $? -eq 1 ]
    then
	    sudo pip3 install --no-cache-dir --disable-pip-version-check -q 'ansible==2.10.2'
	    pip3 show ansible >> /dev/null
	    if [ $? -eq 0 ]
	    then
		    echo -e "\n\n\033[1mSuccessefully installed ansible-2.10.2 ansible-base-2.10.14\033[0m"
        fi

    #elif [[ `ansible --version | sed -n 1p` =~ $ansible_version ]]
    #then
    else
        echo -e "\n\n\033[1mAnsible pre-installed ansible-2.10.2 ansible-base-2.10.14\033[0m"
    
    fi
}




ansible_setup()
{
    #configuring inventory file for ansible

    server_ip="$1"
    usr_name="$2"
    usr_pass="$3"
    home_dir="$4"
    connection_type="ssh"
    [ -f ${home_dir}/Desktop/.NAS/.ip.txt ]
    if [ $? -eq 1 ]
    then
	    mkdir ${home_dir}/Desktop/.NAS
	    #echo "[NASserver]" > /.NAS/.ip.txt
    fi
    echo "${server_ip} ansible_user=${usr_name} ansible_password=${usr_pass} ansible_connection=${connection_type}" > ${home_dir}/Desktop/.NAS/.ip.txt

    #configuring ansible.cfg file

    [ -d /etc/ansible/ ]
    if [ $? -eq 1 ]
    then
	    sudo mkdir /etc/ansible/
    fi
    echo -e "[defaults]\ninventory=${home_dir}/Desktop/.NAS/.ip.txt\nhost_key_checking=False\ndeprecation_warnings=False\ncommand_warnings=False" | sudo tee /etc/ansible/ansible.cfg 

    sudo dnf list installed | grep epel-release
    if [ $? -eq 1 ]
    then
        sudo ping -c 1 8.8.8.8 &>> /dev/null
        if [ $? -eq 0 ]
        then 
            sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y &>> /dev/null
            sudo dnf upgrade &>> /dev/null
            
            sudo dnf list installed | grep sshpass
            if [ $? -eq 1 ]
            then
                sudo ping -c 1 8.8.8.8 &>> /dev/null    
                if [ $? -eq 0 ]
                then
                    sudo dnf install sshpass -y  &>> /dev/null
                    if [ $? -eq 0 ] 
                    then
                        sudo dnf clean dbcache &>> /dev/null
                        echo -e "\nSuccessfully installed sshpass.x86_64 package!!!"
                    else 
                        echo -e "\nUnable to install required packages!!!"
                        return 1
                    fi
                elif [ $? -eq 2 ]
                then   
                    echo -e "\nPlease check your internet connectivity!!! and re-run program."
                    return 1
                fi
            elif [ $? -eq 0 ]
            then    
                echo -e "\nsshpass.86_64 package is already installed!!!"
            fi
        elif [ $? -eq 2 ]
        then
            echo -e "\nPlease check your internet connectivity!!! and re-run program."
            return 1
        fi

    elif [ $? -eq 0 ]
    then
        sudo dnf upgrade &>> /dev/null
        sudo dnf list installed | grep sshpass
        if [ $? -eq 1 ]
        then
            sudo ping -c 1 8.8.8.8 &>> /dev/null
            if [ $? -eq 0 ]
            then
                sudo dnf install sshpass -y &>> /dev/null
                if [ $? -eq 0 ]
                then 
                    sudo dnf clean dbcache &>> /dev/null
                    echo -e "\nSuccessfully installed sshpass.x86_64 package"
                else
                    echo -e "\nUnable to install required packages"
                    return 1
                fi
            elif [ $? -eq 2 ] 
            then
                echo -e "\nPlease check your internet connectivity and re-run program."
                return 1
            fi
        elif [ $? -eq 0 ]
        then
            echo -e "\nsshpass.86_64 package is already installed!!!"
        fi

    fi

    sleep 5
    return 3
}



spin2() #spin function for rotating the array of \ | -- /
{
        spinner=( '|' '/' "--" '\' )
        var="$1"
        echo -e "\n"
        tput civis
        while [ 1 ]
        do
                for i in ${spinner[@]};
                do
                        echo -ne "\r$var $i ";
                        sleep 0.1;
                done
        done

}


<< load
load_animation()
{
    tput civis
    while [ 1 ]
        do
            echo -ne "."
            sleep 0.5
        done
    tput cnorm
}
load



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