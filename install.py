#!/usr/bin/env python3
import os
import shutil
import requests
import tarfile
from bs4 import BeautifulSoup
import getpass
import subprocess


def install_dependencies():
    # Install dependencies
    dependencies_debian = ['git', 'cmake', 'build-essential', 'libssl-dev', 'zlib1g-dev', 'libpcre3-dev', 'pkg-config',
                           'libc-ares-dev', 'libre2-dev']
    dependencies_archlinux = ['base-devel', 'pcre', 'zlib', 'openssl', 'cmake', 'pkgconf', 'c-ares', 're2']
    sudo_password = getpass.getpass("Enter your sudo password: ")

    if detected_os == 'debian':
        print("Installing dependencies...")
        for package in dependencies_debian:
            os.system(f"echo {sudo_password} | sudo apt-get install -y {package}")

    elif detected_os == 'archlinux':
        print("Installing dependencies...")
        for package in dependencies_archlinux:
            os.system(f"echo {sudo_password} | sudo -S pacman -S --noconfirm {package}")


def detect_os():
    check_os = shutil.which('apt-get')
    if check_os:
        return 'debian'
    check_os = shutil.which('pacman')
    if check_os:
        return 'archlinux'
    print("This script only supports Debian and Arch Linux.")
    exit(1)


def get_versions():
    request = requests.get('http://nginx.org/en/download.html')
    soup = BeautifulSoup(request.text, 'html.parser')
    tables = soup.find_all('table')
    versions_output = []
    for table in tables:
        links = table.find_all('a')
        for tag in links:
            if tag.get('href').endswith('.tar.gz'):
                type = table.find_previous('h4').text
                url = tag.get('href')
                version = url.split('/')[-1].replace('.tar.gz', '')
                versions_output.append({'type': type, 'version': version, 'url': url})
    return versions_output


def select_version_prompt(versions_list):
    print('Choose a version to install:')
    print(f"{'Index':<5}\t{'Type':<15}\t{'Version':<10}\t{'URL'}")
    for i, version in enumerate(versions_list):
        print(f"{i:<5}\t{version['type']:<15}\t{version['version']:<10}\t{version['url']}")
    choice = int(input("\nEnter the index of the version to install: "))
    user_selected_version = versions_list[choice]
    print(f"\nSelected version: {user_selected_version['version']} ({user_selected_version['type']})")
    return user_selected_version


def download_version(version):
    print(f"\tDownloading {version['version']}...")
    url = "https://nginx.org" + version['url']
    request = requests.get(url)
    with open(f"{version['version']}.tar.gz", 'wb') as file:
        file.write(request.content)

def remove_if_exists():
    try:
        shutil.rmtree(selected_version['version'])
    except FileNotFoundError:
        pass

def untar_version(version):
    print(f"\tExtracting {version['version']}...")
    # Remove the existing directory if it exists
    try:
        shutil.rmtree(version['version'])
    except FileNotFoundError:
        pass
    tarfile.open(f"{version['version']}.tar.gz", 'r:gz').extractall(filter='data')


def configure_nginx(version):
    print(f"\tConfiguring {version['version']} with --with-compat...")
    os.chdir(version['version'])
    result = subprocess.run(['./configure', '--with-compat'], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Configuration failed: {result.stderr}")
        exit(1)
    print(result.stdout)
    os.chdir('..')


def download_otel_module(nginx_dir):
    configured_nginx_build_dir = os.path.join(nginx_dir, 'objs')
    print("\t\tConfigured nginx build directory: " + configured_nginx_build_dir)

    print("\t\tCloning nginx-otel repository...")
    # Remove the existing directory if it exists
    try:
        shutil.rmtree('nginx-otel')
    except FileNotFoundError:
        pass
    subprocess.run(['git', 'clone', 'https://github.com/nginxinc/nginx-otel.git'])

    # Change to the nginx-otel directory
    os.chdir('nginx-otel')

    os.mkdir("build")
    os.chdir("build")

    # Configure the module
    subprocess.run(['cmake', f'-DNGX_OTEL_NGINX_BUILD_DIR=../../{nginx_dir}/objs', '..'], cwd=os.getcwd())
    subprocess.run(['make'], cwd=os.getcwd())


# Detect OS and cancel if not supported
detected_os = detect_os()
# install_dependencies()

# Get nginx versions
versions = get_versions()

# Select version
selected_version = select_version_prompt(versions)

# Download and extract version
download_version(selected_version)
remove_if_exists()
untar_version(selected_version)
nginx_dir = os.path.join(os.getcwd(), selected_version['version'])

# Auto-configure - adjust paths
configure_nginx(selected_version)

# Download additional modules
print("\tDownloading additional modules...")

# Otel module - https://github.com/nginxinc/nginx-otel
download_otel_module(nginx_dir)

# Brotli module - https://github.com/google/ngx_brotli

print("Current directory: " + os.getcwd())