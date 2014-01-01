#!/usr/sbin/bash

# This script is to be used to check for the availability of new mail in several maildir accounts
# [[file:~/.config/awesome/rc.lua::---%20**%20mail%20textbox%20widget][rc.lua]]
# New mail checking is performed in the maildir/account/inbox/new folder of each respective account, as new mail
# appears here

# Header of the string to display in awesome bar
printf -v texto "mymailtextbox:set_markup('[ <span color=\"white\">Mail</span> "

default_action=$1

call_account() {

    # save input arguments in variables
    account_name=$1
    account_alias=$2
    action=$3

    # kind of notifier following account
    case $account_name in
        "inventati")
            notifier=gnubiff;;
        "iphc")
            notifier=gnubiff;;
        "reyes")
            notifier=checkgmail;;
        "curro")
            notifier=checkgmail;;
        "otra")
            notifier=checkgmail;;
        *) ;;
    esac

    # where to store number of new mails: useful to compare next check
    printf -v file_name "/tmp/%s" $account_name

    # reset action
    if ([ "$action" == "reset" ]); then
        echo 0 > $file_name
        return
    fi

    # security: if nb of old mails file doesn't exist, create it
    if [ ! -f $file_name ]; then
        echo 0 > $file_name
        return
    fi

    # nb of files in 'new' folder of the respective account
    # previous
    old_nb_files=`more $file_name`
    # current
    nb_files=`find $HOME/Dropbox/Maildir/$account_name/inbox/new/ -type f | wc -l`
    # overwrite old value
    echo $nb_files > $file_name

    # if nb of files in folder is greater than 0, complete string 'texto' with a new string (to be displayed in
    # awesome bar)
    [[ "$nb_files" -gt 0 ]] && printf -v texto "$texto $account_alias<span color=\"white\">%i</span>" $nb_files

    # open gmail notifier / gnubiff when new mail arrives
    # already open notifier (existing pdi) ?
    output=`ps aux|grep $notifier|grep $account_name`
    set -- $output
    pid=$2

    # Desktop notification: criteria is increase in nb of mails relative to previous check
    # echo $account_name
    # echo "$nb_files"
    # echo "$old_nb_files"
    if ([ "$nb_files" -gt "$old_nb_files" ]);
    then
        # launch notification for all new mails in folder
        for i in $( find $HOME/Dropbox/Maildir/$account_name/inbox/new/ -type f)
        do
            # get infos from mail header
            date=$(sed  -n '/^Date: / {s/^Date: //p;q}' "$i")
            from=$(sed  -n '/^From: / {s/^From: //p;q}' "$i")
            subject=$(sed  -n '/^Subject: / {s/^Subject: //p;q}' "$i")
            # build-up tmp string
            T1='naughty.notify({title = "From '
            T2='", text = "Subject '
            if ([ "$account_name" == "inventati" ]);
            then
                T3='", timeout = 10, ontop = true, height = 135, width = 400, position="top_left", icon="/home/csantos/Pictures/icons/icon-inventati.png", fg="#000000", bg="#FFFFFF"})'
            else
                if ([ "$account_name" == "iphc" ])
                then
                    T3='", timeout = 10, ontop = true, height = 138, width = 470, position="top_left", icon="/home/csantos/Pictures/icons/icon-cnrs.png", fg="#000000", bg="#FFFFFF"})'
                else
                    T3='", timeout = 10, ontop = true, height = 190, width = 470, position="top_left", icon="/home/csantos/Pictures/icons/icon-gmail.png", fg="#000000", bg="#FFFFFF"})'
                fi
            fi
            # create string
            printf -v tmp '%s %-15s %-15s %-15s %-15s\n' "$T1" $from $T2 $subject "$T3"
            # send notification to desktop
            echo $tmp | awesome-client
        done
    fi

    # if new mail and no pid existing, launch notifier and send notification to desktop
    if ([ "$nb_files" -gt 0 ] && [ -z "$pid" ]);
    then
        if ([ "$account_name" == "inventati" ] || [ "$account_name" == "iphc" ]);
        then
            exec `gnubiff -n --systemtray --config ~/.config/gnubiff/gnubiffrc_$account_name` &
        else
            exec `checkgmail -profile=$account_name -no_cookies` &
        fi
    else
        # if no more mail, and pid exists, close gmailchecker / gnubiff (by its pid)
        if ([ "$nb_files" -eq 0 ] && [ "$pid" != " " ]);
        then
            kill -9 $pid >/dev/null 2>&1
        fi
    fi

}

# call previous function for all accounts
call_account "inventati" "i" $default_action
call_account "iphc" "h" $default_action
call_account "otra" "o" $default_action
call_account "curro" "u" $default_action
call_account "reyes" "r" $default_action

# close the text string
printf -v texto "$texto ]')"

# if no mail, change the string
if ([ "$texto" == "mymailtextbox:set_markup('[ <span color=\"white\">Mail</span>  ]')" ]);
then
    printf -v texto "mymailtextbox:set_markup(' [ No Mail ]')"
fi

# update strin
echo $texto | awesome-client

