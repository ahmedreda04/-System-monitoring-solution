#!/bin/bash
LOGS="logs.log"
logDate(){
    echo "$(date)- $1" >> "$LOGS"
}
logNoDate(){
    echo "$1" >> "$LOGS"
}

upTime(){
    # time=$(uptime)--> also prints the Load average so..
    time=$(uptime | awk '{for(i=1; i<=7; i++) printf "%s ", $i; print ""}') #chatgpted tbh
    echo "Device been up for: $time" 
    logNoDate "Device been up for: $time" 
}
kernelVersion(){
    kversion=$(uname -r)
	echo "Kernel version: $kversion"
    logNoDate "Kernel version: $kversion"
}
proccessLoadAvg(){
    # Check if iostat is installed
    if ! command -v iostat &> /dev/null; then
        echo "iostat is not installed. Please install sysstat package."
        return 1
    fi

    # Get the load average using uptime
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g')

    # Extract the 1-minute, 5-minute, and 15-minute load averages
    read -r load_1m load_5m load_15m <<< "$load_avg"

    # Output each load average in a separate row
    echo "1-Minute Load Avg: $load_1m"
    echo "5-Minute Load Avg: $load_5m"
    echo "15-Minute Load Avg: $load_15m"
    
    # Log the load averages
    logNoDate "1-Minute Load Avg: $load_1m"
    logNoDate "5-Minute Load Avg: $load_5m"
    logNoDate "15-Minute Load Avg: $load_15m"
}

mac_batteryHealth(){
    health=$(system_profiler SPPowerDataType | grep -i "Condition\|Cycle Count\|Full Charge Capacity")
    echo "Battery Health: $health"
    logNoDate "Battery Health: $health"
}
linux_batteryHealth(){
    # Check if upower is installed
    if ! command -v upower &> /dev/null; then
        echo "upower is not installed. Please install it to check battery health."
        return 1
    fi
    
    # Get battery status using upower
    battery_info=$(upower -i $(upower -e | grep 'battery') | grep -E "state|percentage|time to empty|time to full|capacity|cycle")
    
    # Log and show battery health information
    echo "Battery Health:"
    echo "$battery_info"
    
    logNoDate "Battery Health: "
    logNoDate "$battery_info"
}

SMARTstatus(){
    # Check if smartctl is installed
    if ! command -v smartctl &> /dev/null; then
        echo "smartctl is not installed. Please install smartmontools."
        return 1
    fi

    # Check if the device exists
    if [ ! -b /dev/sda ]; then
        echo "/dev/sda does not exist. Please check the device name."
        return 1
    fi

    # Get the SMART status with permissive flag
    status=$(sudo smartctl -a -T permissive /dev/sda 2>&1)

    # Check if smartctl ran successfully
    if [ $? -ne 0 ]; then
        echo "Failed to get SMART status for /dev/sda. Error: $status"
        return 1
    fi

    # Log the SMART status
    logNoDate "SMART status for /dev/sda:"
    logNoDate "$status"
}

diskUsage(){
    duStats=$(df -l -h | awk '{gsub("/dev/", "", $1); printf "%-15s %-10s %-10s %-10s\n", $1, $2, $3, $5}')
    echo "$duStats"
    logNoDate "Disk Storage stats:"
    logNoDate "$duStats"
}

mac_cpuUsage(){
    usage=$(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3 + $5}')
    echo "$(date '+%Y-%m-%d %H:%M:%S')- Total CPU usage is: $usage%"
    logNoDate "Total CPU usage is: $usage%"
}

linux_cpuUsage(){
    # if "CPU" doesnt work try "Cpu(s)"
    # 2 w 3 3ashan user w system awel 2 columns
    usage=$(top -n 1 -b | grep "Cpu(s)" | head -n 1 |awk '{print $2 + $3}')
    echo "Total CPU usage is: $usage%"
    logNoDate "Total CPU usage is: $usage%"
}

linux_cpuTemp(){
    CPUthreshold=75

    temp=$(sensors | grep "Core 0" | awk '{print $2}') # "sensors" must be installed

    if [ -z "$temp" ]; then
        echo "Error retrieving CPU temperature"
    elif [ "$temp" -le "$CPUthreshold" ]; then
        echo "$temp C"
        echo "CPU temperature is within the normal range"
        logNoDate "CPU temperature: $temp C"
    else 
        echo "$temp C"
        logNoDate "CPU temperature: $temp C"
        notify-send "Warning: CPU is overheating: $temp C"
    fi
}

mac_cpuTemp(){
    CPUthreshold=75 # Set threshold for warning

    # Get the CPU temperature using powermetrics (requires sudo)
    temp=$(sudo powermetrics --samplers smc | grep "CPU die temperature" | awk '{print $4}' | cut -d 'C' -f1)

    if [ -z "$temp" ]; then
        echo "Error retrieving CPU temperature"
    elif (( $(echo "$temp <= $CPUthreshold" | bc -l) )); then
        echo "$temp°C"
        echo "CPU temperature is within the normal range"
        # Log message (you can replace this with your log function)
        logNoDate "CPU temperature: $temp°C"
    else
        echo "$temp°C"
        echo "Warning: CPU temperature is high!"
        # Log message (you can replace this with your log function)
        logNoDate "CPU temperature: $temp°C"
        # Send notification using osascript
        osascript -e "display notification \"Warning: CPU is overheating: $temp°C\" with title \"CPU Temperature Warning\""
    fi
}

linux_gpuUsage(){
    gpuHealth=""

    #  NVIDIA 
    if command -v nvidia-smi &> /dev/null; then
        nvidiaHealth=$(nvidia-smi)
        gpuHealth+="NVIDIA GPU Health:\n$nvidiaHealth\n"
        gpuTemp=$(nvidia-smi | grep "N/A" | awk '{print $3}' | grep "C")
        if [  "$gpuTemp" -ge "90C" ]; then
            notify-send "GPU temperature is high"   
        fi
            
    fi
    # AMD --> by checking either of two commands (radeontop is deprecated kind of)
    if command -v amdgpu_top &> /dev/null; then
        amdHealth=$(amdgpu_top)
        gpuHealth+="AMD GPU Health:\n$amdHealth\n"
        gpuTemp=$(amdgpu_top | grep "N/A" | awk '{print $3}' | grep "C")
        if [  "$gpuTemp" -ge "90C" ]; then
            notify-send "GPU temperature is high"   
        fi
    elif command -v radeontop &> /dev/null; then
        amdHealth=$(radeontop -d)
        gpuHealth+="AMD GPU Health:\n$amdHealth\n"
        gpuTemp=$(radeontop -d | grep "N/A" | awk '{print $3}' | grep "C")
        if [  "$gpuTemp" -ge "90C" ]; then
            notify-send "GPU temperature is high"   
        fi

    fi
    # Intel 
    if command -v intel_gpu_top &> /dev/null; then
        intelHealth=$(intel_gpu_top -l 1)
        gpuHealth+="Intel GPU Health:\n$intelHealth\n"
        gpuTemp=$(intel_gpu_top -1 1 | grep "N/A" | awk '{print $3}' | grep "C")
        if [  "$gpuTemp" -ge "90C" ]; then
            notify-send "GPU temperature is high"   
        fi
    fi
    echo "$gpuHealth"
    logNoDate "$gpuHealth"
}
mac_gpuUsage(){
    gpuHealth=$(system_profiler SPDisplaysDataType | head -n 10)
    echo "$gpuHealth"
    logNoDate "$gpuHealth"
    }

linux_memory_usage() {
    memUsage=$(free -h)
    echo "$memUsage"
    logNoDate "$memUsage"
}

mac_memory_usage() {
    memUsage=$(top -l 1 | grep "PhysMem")
    echo "$memUsage"
    logNoDate "$memUsage"
}

mac_ip(){
    ##LOCAL:
    local=$(ifconfig | grep "inet" | head -n 1 | awk '{print $2}')
    echo "Local ip is: $local"
    logNoDate "Local ip is: $local"

    ## GLOBAL
    global=$(curl ifconfig.me)
    echo "Global ip is: $global"
    logNoDate "Global ip is: $global"
}

linux_ip(){
    local=$(ip a | grep "inet " | head -n 1 | awk '{print $2}')
    echo "Local ip is: $local"
    logNoDate "Local ip is: $local"

    ## GLOBAL
    #apt install curl ---> if needed
    #use icanhazip.com is ifconfig doesnt work bardo
    global=$(curl ifconfig.me)
    echo "Global ip is: $global"
    logNoDate "Global ip is: $global"
}

internetStats(){
    # ping - download - upload speeds
    stats=$(speedtest-cli --simple)
    echo "Internet speed is: $stats"
    logNoDate "Internet speed is: $stats"
}

sockets(){
    # Get the total number of sockets
    totalN=$(ss -s | grep "Total" | awk '{print $2}'| head -n 1)
    echo "Total number of opened sockets: $totalN"
    logNoDate "Total number of opened sockets: $totalN"

    # Get the total number of TCP sockets
    tcp=$(ss -s | grep "TCP" | awk '{print $2}' | head -n 1)
    echo "Total number of TCP used sockets: $tcp"
    logNoDate "Total number of TCP used sockets: $tcp"

    # Get the total number of UDP sockets
    udp=$(ss -s | grep "UDP" | awk '{print $2}')
    echo "Total number of UDP used sockets: $udp"
    logNoDate "Total number of UDP used sockets: $udp"
}
runningProcesses(){
    num=$(ps aux | wc -l)
    echo "Total number of running processes: $num"
    logNoDate "Total number of running processes: $num"
}

check_os() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        $1
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        $2
    else
        echo "Unsupported OS"
        logDate "Unsupported OS"
    fi
}
generateHTMLSection() {
    local title="$1"
    local content="$2"
    echo "<div class='section'>" >> "$report_file"
    echo "<h2>$title</h2>" >> "$report_file"
    echo "<pre>" >> "$report_file"
    echo "$content" >> "$report_file"
    echo "</pre>" >> "$report_file"
    echo "</div>" >> "$report_file"
}

generate_full_report() {
    report_file="report.html"
    # Start HTML structure
    echo "<html>" > "$report_file"
    echo "<head><title>System Report</title><style>body { font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; padding: 20px;} h1 { color: #4CAF50; text-align: center; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; margin-bottom: 20px;} h2 { color: #555; margin-top: 20px;} p { line-height: 1.6; margin-bottom: 15px;} pre { background-color: #f0f0f0; padding: 15px; border-radius: 4px; font-family: Courier, monospace; overflow-x: auto; white-space: pre-wrap;} .section { padding: 10px; background-color: #ffffff; margin-bottom: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);}</style></head>" >> "$report_file"
    echo "<body><h1>System Report</h1>" >> "$report_file"
    
    # Generate sections dynamically
    generateHTMLSection "Uptime" "$(upTime)"
    generateHTMLSection "Kernel Version" "$(kernelVersion)"
    generateHTMLSection "Process Load Average" "$(proccessLoadAvg)"
    generateHTMLSection "CPU Usage" "$(check_os "linux_cpuUsage" "mac_cpuUsage")"
    generateHTMLSection "CPU Temperature" "$(check_os "linux_cpuTemp" "mac_cpuTemp")"
    generateHTMLSection "GPU Usage" "$(check_os "linux_gpuUsage" "mac_gpuUsage")"
    generateHTMLSection "Disk Usage" "$(diskUsage)"
    generateHTMLSection "Memory Usage" "$(check_os "linux_memory_usage" "mac_memory_usage")"
    generateHTMLSection "IP Address" "$(check_os "linux_ip" "mac_ip")"
    generateHTMLSection "Internet Speed" "$(internetStats)"
    generateHTMLSection "Sockets" "$(sockets)"
    generateHTMLSection "SMART Status" "$(SMARTstatus)"
    generateHTMLSection "Battery Health" "$(check_os "linux_batteryHealth" "mac_batteryHealth")"
    generateHTMLSection "Running Processes" "$(runningProcesses)"

    # End HTML structure
    echo "</body></html>" >> "$report_file"

    # Open the HTML report using Windows' default browser
    check_os "explorer.exe $report_file" "open $report_file"
    logNoDate "HTML report generated successfully: $report_file" 
}

##########
#TODO:
#error handling lel missing packages
#handling lel critical events
#########
# CPU Temp:
#   - garabt htop 3ashan sensors w el temperature feha msh shaghala 
#   - top mafhash temperature
#   - nazelt lm-sensors w libsensors-dev for htop
#########