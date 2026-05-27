# Google-Managed SSL Certificates with DNS Authorization

This directory contains scripts to set up Google-managed SSL certificates using **Certificate Manager** and **DNS Authorization**. This method is more robust than Load Balancer authorization as it doesn't require the domain to be already pointing to the LB's IP for provisioning to start.

## Prerequisites

- You must have the `gcloud` CLI installed and authenticated.
- The `GCP_PROJECT_ID` environment variable must be set.
- You must have permissions to modify Certificate Manager and Compute Engine resources.

## Setup Process

### Step 1: Create DNS Authorizations
Run the first script to create the authorization resources. This script will output **CNAME records**.

```bash
chmod +x 01_dns_auth.sh
./01_dns_auth.sh
```

**CRITICAL:** You must take the CNAME records provided in the output and add them to your DNS provider (Cloudflare, AWS Route53, etc.).

### Step 2: Create the Certificate
Once the DNS records are added, run the second script to create the managed certificate.

```bash
chmod +x 02_create_cert.sh
./02_create_cert.sh
```

GCP will now verify the DNS records and provision the certificate. This can take anywhere from 5 to 30 minutes. 

You can check the status with:
```bash
gcloud certificate-manager certificates describe stage-cert-rocketpay-udharpay
```

### Step 3: Attach to Load Balancer
Once the certificate status is `ACTIVE`, run the third script to create a Certificate Map and attach it to your Load Balancer's HTTPS proxy.

```bash
chmod +x 03_attach_cert.sh
./03_attach_cert.sh
```

**Note:** Attaching a certificate map to a proxy will override any individual SSL certificates currently attached to that proxy.

## Troubleshooting

- **Wildcard Domains:** This setup uses `*.rocketpay.co.in` and `*.udharpay.com`. These cover all first-level subdomains (e.g., `api.rocketpay.co.in`, `admin.udharpay.com`).
- **Provisioning Failed:** Ensure the CNAME records are correctly added and have propagated. Use `dig` or `nslookup` to verify the CNAME record existence.
