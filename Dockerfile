FROM archlinux:base-devel
RUN mkdir /out
RUN pacman-key --init
RUN pacman -Sy --noconfirm archlinux-keyring && pacman -Su --noconfirm
RUN pacman -Syyuq --noconfirm
RUN pacman -S sudo tar unzip wget --noconfirm
RUN useradd -m buildhelper
RUN echo "buildhelper ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo
WORKDIR /home
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
