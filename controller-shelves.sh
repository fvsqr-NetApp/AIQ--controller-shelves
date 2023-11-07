#!/usr/local/bin/bash

SERIAL_FILE=/opt/aiq/serials

CSV=/csv/$(date '+%Y-%m-%d'--controller-shelves.csv)

COUNTER=0
echo SERIAL,clustername,node_system_id,node_hostname,node_model,node_ontap,node_partner_system_id,node_partner_hostname,node_raw_capacity_tib,node_used_capacity_tib,stackname,shelf_name,shelf_type,shelf_disk_count,shelf_serial,shelf_model,shelf_notes > $CSV

while read SERIAL
do
    COUNTER=$[COUNTER + 1]

    RESP=`curl -s --no-progress-meter --location --request GET "https://api.activeiq.netapp.com/v1/clusterview/get-node-summary/$SERIAL" \
      --header 'accept: application/json' \
      --header "authorizationToken: $AUTH_TOKEN"`

    message=`echo $RESP | jq -r '.message'`

    if [ "$message" = "Unauthorized" ]; then
        echo "Unauthorized. Please check your auth token."
        exit
    fi

    node=`echo $RESP | jq -r '.data[0]'`

    RESP=`curl -s --no-progress-meter --location --request GET "https://api.activeiq.netapp.com/v1/clusterview/get-stack-visualization/$SERIAL" \
          --header 'accept: application/json' \
          --header "authorizationToken: $AUTH_TOKEN"`

    shelves=`echo $RESP | jq -r '.data.stack_details'`


    echo
    echo '----------------------------------------------------------------'
    echo
    echo "found Node Info for serial $SERIAL":
    nodeinfo=`echo $node | jq .`
    echo $nodeinfo

    clustername=`echo $node | jq '.cluster_name'`
    
    node_system_id=`echo $node | jq '.system_id'`
    node_hostname=`echo $node | jq '.hostname'`
    node_model=`echo $node | jq '.model'`
    node_ontap=`echo $node | jq '.release_version'`
    node_partner_system_id=`echo $node | jq '.ha_partner_system_id'`
    node_partner_hostname=`echo $node | jq '.ha_partner_hostname'`
    node_raw_capacity_tib=`echo $node | jq '.raw_capacity_tib'`
    node_used_capacity_tib=`echo $node | jq '.used_capacity_tib'`

    RESP=`curl -s --no-progress-meter --location --request GET "https://api.activeiq.netapp.com/v1/clusterview/get-stack-details/$SERIAL" \
      --header 'accept: application/json' \
      --header "authorizationToken: $AUTH_TOKEN"`

    stackcount=`echo $RESP | jq -r '.data | length'`

    echo
    echo "found $stackcount stacks"

    for ((i=0; i<$stackcount; i++)); do
      stackname=`echo $RESP | jq -r '.data | .['$i'].name'`
      
      shelfcount=`echo $RESP | jq -r '.data | .['$i'].shelf | length'`
      echo "found $shelfcount shelves for stack $stackname"
      for ((j=0; j<$shelfcount; j++)); do
        shelf=`echo $RESP | jq -r '.data | .['$i'].shelf | .['$j'] | del(.disk)'`

        shelf_name=`echo $shelf | jq '.name'`
        shelf_disk_count=`echo $shelf | jq '.disk_count'`
        shelf_serial=`echo $shelf | jq '.serial_no'`
        shelf_model=`echo $shelf | jq '.model'`
        shelf_notes=`echo $shelf | jq '.notes'`

        shelf_type=`echo $shelves | jq -r '.[] | select(.colour_a=="'$stackname'") | .shelf_details[] | select(.shelf_serial_no=='$shelf_serial') | .shelf_type'` 
        
        echo \'$SERIAL,$clustername,$node_system_id,$node_hostname,$node_model,$node_ontap,$node_partner_system_id,$node_partner_hostname,$node_raw_capacity_tib,$node_used_capacity_tib,$stackname,$shelf_name,$shelf_type,$shelf_disk_count,$shelf_serial,$shelf_model,$shelf_notes >> $CSV
        
      done
    done

done <$SERIAL_FILE

# replace commas with semicolons, after replace dots with comma (we only have numbers)
#sed -i '' -e 's/\,/;/g' $CSV
#sed -i '' -e 's/\./,/g' $CSV
