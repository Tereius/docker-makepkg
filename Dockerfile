FROM archlinux:base-devel
RUN mkdir /out
RUN echo "[multilib]" >> /etc/pacman.conf && echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN echo 'MAKEFLAGS="-j$(nproc)"' >> /etc/makepkg.conf
RUN pacman-key --init
RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Su --noconfirm
RUN pacman -Syyuq --noconfirm
RUN pacman -S sudo tar unzip wget --noconfirm
RUN useradd -u 10002 -m buildhelper
RUN echo "buildhelper ALL=(root) NOPASSWD: /usr/bin/pacman, /usr/bin/pacsync" | sudo EDITOR='tee -a' visudo
WORKDIR /home
COPY entrypoint.sh ./
COPY entrypoint_one.sh ./
RUN chmod +x entrypoint.sh
RUN chmod +x entrypoint_one.sh
ENV TERM=linux
ENV CONTINUOUS_INTERVAL_SEC=600
ENTRYPOINT ["./entrypoint_one.sh"]
