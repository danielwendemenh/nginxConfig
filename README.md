# nginxConfig

This repository contains `nginx` configuration files for setting up and serving the domain **danielwende.com**.

## Files

- **nginx.conf** — Main nginx configuration file.
- **danielwende.com** — Server block (vhost) configuration for danielwende.com.

## Usage

### 1. Clone the repo

```bash
git clone https://github.com/danielwendemenh/nginxConfig.git
cd nginxConfig
```

### 2. Copy the files to your nginx configuration directory

For most Linux systems:

```bash
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo cp danielwende.com /etc/nginx/sites-available/danielwende.com
```

### 3. Enable the site

```bash
sudo ln -s /etc/nginx/sites-available/danielwende.com /etc/nginx/sites-enabled/
```

### 4. Test and reload nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

**Note**: Make sure your server block in `danielwende.com` points to the correct `root` directory and has valid SSL settings (if used).
