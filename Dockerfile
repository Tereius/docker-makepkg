FROM archlinux:multilib-devel
ARG AURUTILS_PKG_URL=https://aur.archlinux.org/cgit/aur.git/snapshot/aur-748cb7f5d3ab29f55518f472669c54175c5df538.tar.gz 
RUN mkdir /out
RUN echo 'MAKEFLAGS="-j$(nproc)"' >> /etc/makepkg.conf
RUN pacman-key --init
RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Su --noconfirm
RUN pacman -Syyuq --noconfirm
RUN pacman -S sudo tar unzip wget git pacutils perl-json-xs reflector --noconfirm
RUN git config --system init.defaultBranch master
RUN useradd -u 10002 -m buildhelper
RUN echo "buildhelper ALL=(root) NOPASSWD: /usr/bin/pacman, /usr/bin/pacsync" | sudo EDITOR='tee -a' visudo
WORKDIR /home
# build, install aurutils for the first run
RUN mkdir aurutils && wget -q --content-disposition "${AURUTILS_PKG_URL}" -P ./ && tar xzf *.tar.gz -C aurutils --strip-components=1 && chown -R buildhelper:buildhelper ./aurutils
RUN su buildhelper -c "cd ./aurutils && makepkg -m -f -c -C -s -i --noconfirm" && rm -r aurutils

COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh
ENV TERM=linux
ENV ARCH_REPO_NAME=unknown
ENV CONTINUOUS_INTERVAL_SEC=600
ENV LIBGL_ALWAYS_SOFTWARE=true
ENTRYPOINT ["./entrypoint.sh"]
