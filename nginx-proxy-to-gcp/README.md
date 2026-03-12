# Nginx Reverse Proxy (AWS to GCP)

This directory contains scripts and configurations to quickly launch an AWS EC2 Virtual Machine that acts as a transparent Nginx reverse proxy.

## Files
1. `launch_vm.sh`: A script containing the `aws ec2 run-instances` command to provision the VM.
2. `startup.sh`: The metadata startup script passed to the VM immediately on boot via `--user-data`. It updates packages, installs Nginx, and applies the local configuration over the default one.
3. `nginx.conf`: A standalone copy of the exact configuration being utilized for the proxy setup.

## Setup Instructions

1. If you are going to launch the instance and rely on `--user-data` to execute `startup.sh`, ensure `nginx.conf` is actually placed at `~/nginx.conf` (`/root/nginx.conf` since `cloud-init` runs as root) on the instance, or you may need to SSH in, copy `nginx.conf` to your home directory, and execute `sudo ./startup.sh` manually.

2. Make sure you have the AWS CLI configured, make the launch script executable, and run it:
   ```bash
   chmod +x launch_vm.sh
   ./launch_vm.sh
   ```

## Nginx Proxy Details

The specific configuration in `nginx.conf` correctly preserves and forwards everything from the original client:
- **Methods**: `GET`, `POST`, `OPTIONS`, `PUT`, etc.
- **Paths & Query Params**: Forwarded without modification since `proxy_pass` does not contain a trailing slash or URI.
- **Cookies & Headers**: Passed fully using `proxy_pass_request_headers on;` and by setting `Host $http_host`.
- **Client IP**: `X-Real-IP` and `X-Forwarded-For` are injected so the target server knows the actual client IP, not just the proxy VM's IP.
