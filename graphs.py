import subprocess
import matplotlib.pyplot as plt
import re


# Get Disk Usage Function (unchanged)
def get_disk_usage():
    result = subprocess.run(['df', '-l', '-H'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    disk_data = []
    lines = result.stdout.splitlines()

    # Skip the header line and process each subsequent line
    for line in lines[1:]:
        columns = line.split()
        if len(columns) >= 3:
            disk_name = columns[0]  # Disk name (e.g., /dev/sda1)
            used_space = columns[2]  # Used space (e.g., 20G)
            # Filter out any non-relevant or extra data, e.g., loop devices, etc.
            # if "/dev/" in disk_name:
            disk_data.append((disk_name, used_space))
    
    return disk_data


# Get CPU Usage Function for WSL2 (Linux-based)
def get_CPU_usage():
    # Using top command to get CPU usage in WSL2
    command = "top -n 1 -b | grep \"Cpu(s)\" | head -n 1 |awk '{print $2 + $3}'"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode != 0:
        raise Exception("Command failed to execute")

    cpu_usage = result.stdout.strip()  # Extracting the value
    return float(cpu_usage) if cpu_usage else 0.0

# Get Memory Usage Function for WSL2 (Linux-based)
def get_Memory_usage():
    # Using free command to get memory usage in WSL2
    command = "free -m | grep Mem | awk '{print $3, $4}'"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode != 0:
        raise Exception("Command failed to execute")

    # Extracting the memory data
    memory_data = result.stdout.strip().split()
    used_memory = float(memory_data[0])  # Used memory in MB
    free_memory = float(memory_data[1])  # Free memory in MB

    return [free_memory, used_memory]

# Plot Disk Usage (unchanged)
def plotDisk(dataList):
    y = [data[0] for data in dataList]  # List of disk names
    x = [data[1] for data in dataList]  # List of used space

    yy = []  # To store disk names
    xx = []  # To store used space in GB

    regex = r"/dev/"
    for disk in y:
        if regex in disk:
            yy.append(disk.replace("/dev/", ""))  # Clean the disk names

    for space in x:
        if space.endswith('G'):
            xx.append(float(space[:-1]))  # Convert GB to float
        elif space.endswith('M'):
            xx.append(float(space[:-1]) / 1024)  # Convert MB to GB
        else:
            xx.append(0)

    # Debugging step: Check lengths and values of yy and xx
    print(f"Disk Names (yy): {yy}")
    print(f"Used Space (xx): {xx}")

    # Check if lengths of yy and xx match
    if len(yy) != len(xx):
        print(f"Mismatch in lengths: yy = {len(yy)}, xx = {len(xx)}")
        return  # Skip plotting if there's a mismatch

    plt.figure(figsize=(20, 6))
    plt.bar(yy, xx, color='green')
    plt.xlabel('Used Space (GB)')
    plt.title('Disk Usage')
    
    # Save the plot to assets/ directory
    plt.savefig('assets/disk_usage.png')  # Saving the plot to assets/disk_usage.png
    plt.close()  # Close the plot to avoid warnings


# Plot CPU Usage (unchanged)
def plotCpu(cpu_usage):
    entities = ["User","System"]
    plt.bar(entities, [cpu_usage], color='green')

    plt.ylabel('Usage (%)')
    plt.title('CPU Usage')
    plt.savefig('assets/cpu_usage.png')  # Save to assets/cpu_usage.png
    plt.close()  # Close the plot to avoid warnings

# Plot Memory Usage (unchanged)
def plotMemory(memoryUsage):
    entities = ["Free", "Used"]
    
    plt.bar(entities, memoryUsage, color='green')
    plt.ylabel('Memory (MB)')
    plt.title('Memory Usage')
    plt.savefig('assets/memory_usage.png')  # Save to assets/memory_usage.png
    plt.close()  # Close the plot to avoid warnings

# Main Code Execution (unchanged)
if __name__ == "__main__":
    disk_data = get_disk_usage()
    cpuUsage = get_CPU_usage()
    memoryUsage = get_Memory_usage()
    
    # Plot and save the graphs
    plotDisk(disk_data)
    plotCpu(cpuUsage)
    plotMemory(memoryUsage)
