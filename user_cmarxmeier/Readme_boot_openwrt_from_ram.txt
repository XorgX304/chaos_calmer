# example for smartfrog aka. zmodo ZH-IXU1D-MAC with HI3518c

# Kernel settings
setenv 'bootargs totalmem=64M mem=40M sensor=ov9712 console=ttyAMA0,115200'
# Download initramfs via ymodem to RAM
loady 0x82000000 
> ymodem file upload "openwrt-hisilicon-armv5tej-3.0.8-initramfs-uImage" over terminal
# Start from RAM
bootm 0x82000000
