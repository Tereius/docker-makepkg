FROM archlinux:base-devel
RUN mkdir /out
RUN echo "[multilib]" >> /etc/pacman.conf && echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN echo 'MAKEFLAGS="-j$(nproc)"' >> /etc/makepkg.conf
RUN pacman-key --init
RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Su --noconfirm
RUN pacman -Syyuq --noconfirm
RUN pacman -S sudo tar unzip wget git pacutils perl-json-xs reflector --noconfirm
RUN useradd -u 10002 -m buildhelper
RUN echo "buildhelper ALL=(root) NOPASSWD: /usr/bin/pacman, /usr/bin/pacsync" | sudo EDITOR='tee -a' visudo
WORKDIR /home
# build, install aurutils for the first run
RUN wget -q --content-disposition "https://aur.archlinux.org/cgit/aur.git/snapshot/aurutils.tar.gz" -P ./ && tar xzf *.tar.gz && chown -R buildhelper:buildhelper ./aurutils
RUN su buildhelper -c "cd ./aurutils && makepkg -m -f -c -C -s -i --noconfirm --skipinteg"

COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh
ENV TERM=linux
ENV ARCH_REPO_NAME=unknown
ENV CONTINUOUS_INTERVAL_SEC=600
ENTRYPOINT ["./entrypoint.sh"]
