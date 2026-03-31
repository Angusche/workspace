export DISPLAY=:0;xhost +
export LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri
export LIBVA_DRIVER_NAME=iHD
export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu:~/sw_val/bin
export GST_GL_PLATFORM=egl
export GST_GL_API=gles2
#export XDG_RUNTIME_DIR=/tmp
export GST_PLUGIN_PATH=/usr/lib/gstreamer-1.0/
rm -rf ~/.cache/gstreamer-1.0
export prj=ARL_VIC
