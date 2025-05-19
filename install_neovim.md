# Download AppImage:
```
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
```

# Expose nvim globally:
```
mkdir -p /opt/nvim
mv nvim-linux-x86_64.appimage /opt/nvim/nvim
```

# And the following line to your shell config (~/.bashrc, ~/.zshrc, ...):
```
#export PATH="$PATH:/opt/nvim/"
```

# Set the below with the correct path:
```
CUSTOM_NVIM_PATH=/opt/nvim/nvim
```
# then run the rest of the commands:
```
set -u
sudo update-alternatives --install /usr/bin/ex ex "${CUSTOM_NVIM_PATH}" 110
sudo update-alternatives --install /usr/bin/vi vi "${CUSTOM_NVIM_PATH}" 110
sudo update-alternatives --install /usr/bin/view view "${CUSTOM_NVIM_PATH}" 110
sudo update-alternatives --install /usr/bin/vim vim "${CUSTOM_NVIM_PATH}" 110
sudo update-alternatives --install /usr/bin/vimdiff vimdiff "${CUSTOM_NVIM_PATH}" 110
```

# If the ./nvim-linux-x86_64.appimage command fails, try:
```
./nvim-linux-x86_64.appimage --appimage-extract
./squashfs-root/AppRun --version
```

# Optional: exposing nvim globally:
```
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
nvim
```
