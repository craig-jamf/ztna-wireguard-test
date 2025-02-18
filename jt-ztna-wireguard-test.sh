#!/bin/bash

#Add Domains to check
domains=("map.wandera.com" "jamf.com")

#Add TCP Ports to check
ports=(80 443)

#Perform tests while Jamf Trust is disabled
testWithJamfTrustDisabled=1

#Perform tests while Jamf Trust is enabled
testWithJamfTrustEnabled=1

#Turn on/off specific tests
includeDNSTests=1
includeCurlTests=1
includePortTests=1
includePingTests=1

#Set count for ping test
pingCount=4

#Set timeout (seconds) for curl test
curlTimeout=5

#Set timeout (seconds) for port test
portTimeout=2

#Get timestamp 
unixTimeStamp=$(date +%s)

#Where to place the output files
pathToOutput=""
outputPath="$HOME/Desktop/$unixTimeStamp-JT-Wireguard-Check"

#How long to wait (seconds) for Jamf Trust to enable/disable  before running tests
sleepWait=10

#Automatically save
zipResults=1

function run() {

    mkdir $outputPath
    if [ $testWithJamfTrustDisabled -eq 1 ]
    then
        pathToOutput="$outputPath/disabled.txt"
        disableJamfTrust
        printf "\n=============================== Jamf Trust Disabled ===============================n" >> $pathToOutput
        postDateTime
        doTests
        listSystemDetails
        printf "\n=============================== Jamf Trust Disabled ===============================n" >> $pathToOutput
    fi
    if [ $testWithJamfTrustEnabled -eq 1 ]
    then
        pathToOutput="$outputPath/enabled.txt"
        enableJamfTrust
        printf "\n=============================== Jamf Trust Enabled ===============================n" >> $pathToOutput
        postDateTime
        doTests
        listSystemDetails
        printf "\n=============================== Jamf Trust Enabled ===============================n" >> $pathToOutput
    fi

    if [ $zipResults -eq 1 ]
    then
        zip $outputPath.zip -r -j $outputPath
        rm -rf $outputPath
        echo -e "\nScript Complete. You can find the results here: $outputPath.zip \n"
    else
        echo -e "\nScript Complete. You can find the results here: $outputPath\n"
    fi

}

function disableJamfTrust() {
    #Disable Jamf Trust
    echo -e "\nDisabling Jamf Trust"
    open -a "Jamf Trust" "com.jamf.trust://?action=disable_vpn"
    #Wait for it to finish
    sleep $sleepWait
    echo -e "Jamf Trust Disabled\n"
}

function enableJamfTrust() {
    #Enable Jamf Trust
    echo -e "\nEnabling Jamf Trust"
    open -a "Jamf Trust" "com.jamf.trust://?action=enable_vpn"
    #Wait for it to finish
    sleep $sleepWait
    echo -e "Jamf Trust Enabled\n"
}

function listSystemDetails() {

    echo -e "\n---------------------------------- System Details ----------------------------------\n" >> $pathToOutput
    postMacOSVersion
    postNameServers
    postSystemExtensions
    postNetworkServices
    postIfConfig
    postNetStat
    echo -e "\n---------------------------------- System Details ----------------------------------\n" >> $pathToOutput
}

function postSystemExtensions() {
    extensions=$(systemextensionsctl list)
    echo -e "\nSystem Extensions:\n$extensions" >> $pathToOutput
}

function postIfConfig() {
    ifconfig=$(ifconfig -a -v)
    echo -e "\nifconfig:\n$ifconfig" >> $pathToOutput
}

function postNetStat() {
    netstat=$(netstat -rn)
    echo -e "\nnetstat:\n$netstat" >> $pathToOutput
}

function postNetworkServices() {
    listNetworkServices=$(networksetup -listallnetworkservices)
    echo -e "\nNetwork Services:\n$listNetworkServices" >> $pathToOutput
}

function postMacOSVersion() {
    macOSVersion=$(sw_vers)
    echo -e "\nMacOS Version:\n$macOSVersion" >> $pathToOutput
}

function postNameServers() {
    printf "\nNameservers:\n" >> $pathToOutput
    printf "%s" "$(scutil --dns | grep 'nameserver\[[0-9]*\]')" >> $pathToOutput
    printf "\n" >> $pathToOutput
}

postDateTime(){
    UTCDateTime=$(date -u)
    echo -e "\nTests Initiated (UTC): $UTCDateTime\n" >> $pathToOutput
}

function portTests() {

    echo -e "\n\nPort Tests:\n" >> $pathToOutput
    for port in "${ports[@]}"
    do
        portTest=$(nc -z -v  -G $portTimeout $domain $port  &> /dev/null && echo -e "Connected to $domain on TCP port $port\n"|| echo -e "Couldn't connect to $domain on TCP port $port\n")
        echo -e "$portTest" >> $pathToOutput
    done
}

function curlTests() {

    curl_http_test=$(curl -L -m $curlTimeout --silent --head http://$domain | awk '/^HTTP/' )
    curl_https_test=$(curl -L -m $curlTimeout --silent --head https://$domain |  awk '/^HTTP/' )

    printf "\n\nHTTP Request:\n$curl_http_test" >> $pathToOutput
    printf "\n\nHTTPS Request:\n$curl_https_test" >> $pathToOutput
}

function dnsTests() {
    echo "Domain: $domain" >> $pathToOutput
    echo "Results:" $(host $domain | awk '{print $NF}') >> $pathToOutput

    # Get Current DNS Server
    server_info=$(dig $domain | grep ";; SERVER:" | awk '{ $1=$2=""; print $0 }' | sed 's/^[ \t]*//')
    printf "DNS Server being queried: $server_info" >> $pathToOutput
}

function pingTests() {
    pingTest=$(ping -c $pingCount $domain 2>&1)
    ping6Test=$(ping6 -c $pingCount $domain 2>&1)

    echo -e "\nPing (IPV4):\n$pingTest" >> $pathToOutput
    echo -e "\nPing (IPV6):\n$ping6Test" >> $pathToOutput
}

function doTests() {
    # Loop through the domains and test each one
    for domain in "${domains[@]}"
    do
        echo "Checking $domain"
        echo -e "\n---------------------------------- Tests for $domain ----------------------------------\n" >> $pathToOutput

        if [ $includeDNSTests -eq 1 ]
        then
            dnsTests
        fi

        if [ $includePingTests -eq 1 ]
        then
            pingTests
        fi

        if [ $includeCurlTests -eq 1 ]
        then
            curlTests
        fi

        if [ $includePortTests -eq 1 ]
        then
            portTests
        fi

        echo -e "\n---------------------------------- Tests for $domain ----------------------------------\n" >> $pathToOutput
    done
}

run