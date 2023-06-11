cd /sys/fs/cgroup
sudo echo "+cpu" > cgroup.subtree_control
cd /home/pi/research/threading
gcc threading.c -o threading -lpthread