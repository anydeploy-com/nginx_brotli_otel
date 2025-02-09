#!/bin/bash
# shellcheck disable=SC2164
cd nginx-otel
mkdir build
cd build
cmake -DNGX_OTEL_NGINX_BUILD_DIR=../nginx-1.26.3/objs ..
make
cd ../..

# git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
cd ngx_brotli/deps/brotli
mkdir out && cd out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
cmake --build . --config Release --target brotlienc
cd ../../..


# Build Nginx

cd nginx-1.26.3
export CFLAGS="-m64 -march=native -mtune=native -Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections"
export LDFLAGS="-m64 -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"
./configure --add-module=../ngx_brotli -add-module=../nginx-otel/build --with-compat --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-threads --with-stream --with-stream_ssl_module --with-stream_ssl_preread_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-http_slice_module --with-mail --with-mail_ssl_module --with-compat --with-file-aio --with-http_v2_module --with-ipv6 --with-jemalloc --with-pcre --with-pcre-jit --with-http_degradation_module --with-http_perl_module=dynamic --with-http_v2_hpack_enc --with-http_v2_hpack_dec --with-http_v2_hpack_update --with-http_v2_hpack_filter --with-http_v2_hpack_emul --with-http_v2_hpack_table --with-http_v2_hpack_table_size=4096 --with-http_v2_hpack_table_capacity=4096 --with-http_v2_hpack_table_max_size=4096 --with-http_v2_hpack_table_max_capacity=4096 --with-http_v2_hpack_table_min_size=4096 --with-http_v2_hpack_table_min_capacity=4096 --with-http_v2_hpack_table_inc_size=4096 --with-http_v2_hpack_table_inc_capacity=4096 --with-http_v2_hpack_table_dec_size=4096 --with-http
sudo make install