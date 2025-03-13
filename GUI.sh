#!/bin/bash
source systemMonitor.sh
# graphs="graphs.py"
# cpu_usage_image="cpu_usage.png"
# memory_usage_image="memory_usage.png"
# disk_usage_image="disk_usage.png"
main_menu() {
	zenity --list \
	       --title  "System Monitor" \
	       --column "Select an option" \
		   			"Generate full report" \
		   			"Kernel version" \
		   			"Device's uptime" \
	 				"Proccess-load Metrics (1m,5m,15m)" \
	 				"CPU usage" \
					"CPU temperature" \
					"GPU usage" \
					"Disk usage" \
					"Memory usage" \
					"IP address" \
					"Internet speed" \
					"Sockets" \
					"Smart status" \
					"Battery health" \
					"Running processes" \
			--height=500 \
			--width=750 \
			
			

			
}
show_info() {
    local title="$1"
    local text="$2"
    zenity --info \
        --title "$title" \
        --width=600 \
        --height=400 \
        --text="$text"
}

logDate "System Metrics"
logNoDate " "

while true; do
	choice=$(main_menu) 
	logNoDate "#######################################################"
	case $choice in
		"Generate full report")
			generate_full_report
			;;
		"Kernel version")
			show_info "Kernel Version" "$(kernelVersion -p)"
			;;
		"Device's uptime")
			show_info "Device's uptime" "$(uptime -p)"
			;;
		"Proccess-load Metrics (1m,5m,15m)")
			show_info "Proccess-load Metrics (1m,5m,15m)" "$(proccessLoadAvg)"
				
			;;
		"CPU usage")
			show_info "CPU Usage" "$(check_os "linux_cpuUsage" "mac_cpuUsage")"
			
			;;
		"CPU temperature")
			show_info "CPU Temperature" "$(check_os "linux_cpuTemp" "mac_cpuTemp")" 
			;;
		"GPU usage")
			show_info "GPU Usage" "$(check_os "linux_gpuUsage" "mac_gpuUsage")"
			;;
		"Disk usage")
			show_info "Disk Usage" "$(diskUsage)"
			;;
		"Memory usage")
			show_info "Memory Usage" "$(check_os "linux_memory_usage" "mac_memory_usage")"
			;;
		"IP address")
			show_info "IP Address" "$(check_os "linux_ip" "mac_ip")"
			;;
		"Internet speed") 
                show_info "Internet speed" "$(internetStats)"
			;;
		"Sockets") 
				show_info "Sockets" "$(sockets)"
			;;
		"Smart status")
				show_info "Smart Status" "$(SMARTstatus)"
			;;
		
		"Battery health")
			show_info "Battery Health" "$(check_os "linux_batteryHealth" "mac_batteryHealth")"
			;;
		"Running processes")
			show_info "Running processes" "$(runningProcesses)"
			;;
		*)
			break
			;;
	esac
done


