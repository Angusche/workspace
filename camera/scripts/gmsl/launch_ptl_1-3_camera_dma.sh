gst-launch-1.0 icamerasrc  scene-mode=auto device-name=isx031-3 io-mode=dma_mode printfps=true ! 'video/x-raw(memory:DMABuf),drm-format=UYVY,width=1920,height=1536' ! glimagesink sync=false
