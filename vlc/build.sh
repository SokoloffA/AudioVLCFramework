#!/bin/bash

set -euo pipefail

#######################################
# CONFIGURE_FLAGS
#######################################
export CONFIGURE_FLAGS=(
    --disable-sse

# Components:
    --disable-vlc            # build the VLC media player (default enabled)

# Optional Features and Packages:
    --disable-dbus           # compile D-Bus message bus support (default enabled)

# Optimization options:
    --disable-lua            # disable LUA scripting support (default enabled)
    --disable-vlm            # disable the stream manager (default enabled)
    --disable-sout           # disable streaming output (default enabled)

# Input plugins:
    --disable-archive        # (libarchive support) [default=auto]
    --disable-live555        # enable RTSP input through live555 (default enabled)
    --disable-dc1394         # IIDC FireWire input module [default=auto]
    --disable-dv1394         # DV FireWire input module [default=auto]
    --disable-linsys         # Linux Linear Systems Ltd. SDI and HD-SDI input cards (default enabled)
    --disable-dvdread        # dvdread input module [default=auto]
    --disable-dvdnav         # DVD with navigation input module (dvdnav) [default=auto]
    --disable-bluray         # (libbluray for Blu-ray disc support ) [default=auto]
    --disable-opencv         # (OpenCV (computer vision) filter) [default=auto]
    --disable-smbclient      # (SMB/CIFS support) [default=auto]
    --disable-dsm            # libdsm SMB/CIFS access/sd module [default=auto]
    --disable-sftp           # (support SFTP file transfer via libssh2) [default=auto]
    --disable-nfs            # (support nfs protocol via libnfs) [default=auto]
    --disable-smb2           # (support smb2 protocol via libsmb2) [default=disabled]
    --disable-v4l2           # disable Video4Linux version 2 (default auto)
    --disable-amf-scaler     # disable AMD Scaler API (default auto)
    --disable-amf-enhancer   # disable AMD Enhancer API (default auto)
    --disable-decklink       # disable Blackmagic DeckLink SDI input (default auto)
    --disable-vcd            # disable built-in VCD and CD-DA support (default enabled)
    --disable-libcddb        # disable CDDB for Audio CD (default enabled)
    --disable-screen         # disable screen capture (default enabled)
    --disable-vnc            # (VNC/rfb client support) [default=auto]
    --disable-freerdp        # (RDP/Remote Desktop client support) [default=auto]
    --disable-realrtsp       # Real RTSP module (default disabled)
    --disable-macosx-avfoundation # Mac OS X avcapture (video) module (default enabled on Mac OS X)
    --disable-asdcp          # build with asdcp support enabled [default=auto]

# Mux/Demux plugins:
    --enable-dvbpsi          # build with dvbpsi support enabled [default=auto]
    --disable-gme            # Game Music Emu support (default auto) [default=auto]
    --disable-sid            # C64 sid demux support (default auto)
    --enable-ogg             # Ogg demux support [default=auto]
    --disable-shout          # libshout output plugin [default=auto]
    --disable-matroska       # MKV format support [default=auto]
    --disable-mod            # do not use libmodplug (default auto)
    --disable-mpc            # do not use libmpcdec (default auto)

# Codec plugins:
    --disable-wma-fixed      # libwma-fixed module (default disabled)
    --disable-shine          # MPEG Audio Layer 3 encoder [default=auto]
    --disable-omxil          # openmax il codec module (default disabled)
    --disable-omxil-vout     # openmax il video output module (default disabled)
    --disable-rpi-omxil      # openmax il configured for raspberry pi (default disabled)
    --disable-crystalhd      # crystalhd codec plugin (default auto)
    --disable-mad            # libmad module (default enabled)

    --enable-mpg123          # libmpg123 decoder support [default=auto]
    --disable-gst-decode     # GStreamer based decoding support (currently supports only video decoding) (default auto)
    --disable-merge-ffmpeg   # merge FFmpeg-based plugins (default disabled)
    --disable-avcodec        # libavcodec codec (default enabled)
    --disable-libva          # VAAPI GPU decoding support (libVA) (default auto)
    --disable-dxva2          # DxVA2 GPU decoding support (default auto)
    --disable-d3d11va        # D3D11 GPU decoding support (default auto)
    --disable-avformat       # libavformat containers (default enabled)
    --disable-swscale        # libswscale image scaling and conversion (default enabled)
    --disable-postproc       # libpostproc image post-processing (default auto)

    --enable-faad            # faad codec (default auto)
    --disable-aom            # experimental AV1 codec (default auto) [default=auto]
    --disable-dav1d          # AV1 decoder (default auto) [default=auto]
    --disable-vpx            # libvpx VP8/VP9 encoder and decoder (default auto)
    --disable-twolame        # MPEG Audio Layer 2 encoder [default=auto]
    --disable-fdkaac         # FDK-AAC encoder [default=disabled]
    --disable-a52            # A/52 support with liba52 (default enabled)
    --disable-dca            # DTS Coherent Acoustics support with libdca [default=auto]


    --enable-flac            # libflac decoder/encoder support [default=auto]
    --disable-libmpeg2       # libmpeg2 decoder support [default=auto]

    --disable-vorbis         # Vorbis decoder and encoder [default=auto]
    --disable-tremor         # Tremor decoder support (default disabled)
    --disable-speex          # Speex support [default=auto]

    --disable-opus           # Opus support [default=auto]
    --disable-spatialaudio   # Ambisonic channel mixer and binauralizer [default=auto]
    --disable-theora         # experimental theora codec [default=auto]
    --disable-oggspots       # experimental OggSpots codec [default=auto]
    --disable-daala          # experimental daala codec [default=disabled]
    --disable-schroedinger   # dirac decoder and encoder using schroedinger [default=auto]
    --disable-png            # PNG support (default enabled)
    --disable-jpeg           # JPEG support (default enabled)
    --disable-bpg            # BPG support (default disabled)
    --disable-x262           # H262 encoding support with static libx262 (default disabled)
    --disable-x265           # HEVC/H.265 encoder [default=auto]
    --disable-x264           # H264 encoding support with libx264 (default enabled)
    --disable-x26410b        # H264 10-bit encoding support with libx264 (default enabled)
    --disable-mfx            # Intel QuickSync MPEG4-Part10/MPEG2 (aka H.264/H.262) encoder [default=auto]
    --disable-fluidsynth     # MIDI synthetiser with libfluidsynth [default=auto]
    --disable-fluidlite      # MIDI synthetiser with libfluidsynth [default=auto]
    --disable-zvbi           # VBI (inc. Teletext) decoding support with libzvbi (default enabled)
    --disable-telx           # Teletext decoding module (conflicting with zvbi) (default enabled if zvbi is absent)
    --disable-libass         # Subtitle support using libass (default enabled)
    --disable-aribsub        # ARIB Subtitles support (default enabled)
    --disable-aribb25        # ARIB STD-B25 [default=auto]
    --disable-kate           # kate codec [default=auto]
    --disable-tiger          # Tiger rendering library for Kate streams (default auto)
    --disable-css            # CSS selector engine (default auto)

# Video plugins:
    --disable-gles2          # OpenGL ES v2 support [default=disabled]
#    --with-x                 # use the X Window System
    --disable-xcb            # X11 support with XCB (default enabled)
    --disable-xvideo         # XVideo support (default enabled)
    --disable-vdpau          # VDPAU hardware support (default auto)
    --disable-wayland        # Incomplete Wayland support (default disabled)
    --disable-sdl-image      # SDL image support (default enabled)
    --disable-freetype       # freetype support   (default auto)
    --disable-fribidi        # fribidi support    (default auto)
    --disable-harfbuzz       # harfbuzz support   (default auto)
    --disable-fontconfig     # fontconfig support (default auto)
    --disable-svg            # SVG rendering library [default=auto]
    --disable-svgdec         # SVG image decoder library [default=auto]
    --disable-directx        # Microsoft DirectX support (default enabled on Windows)
    --disable-aa             # aalib output (default disabled)
    --disable-caca           # libcaca output [default=auto]
    --disable-kva            # support the K Video Accelerator KVA (default enabled on OS/2)
    --disable-mmal           # Multi-Media Abstraction Layer (MMAL) hardware plugin (default enable)
    --disable-evas           # use evas output module (default disabled)

#Audio plugins:
    --disable-pulse          # use the PulseAudio client library (default auto)
    --disable-alsa           # support the Advanced Linux Sound Architecture (default auto)
    --disable-oss            # support the Open Sound System OSS (default enabled on FreeBSD/NetBSD/DragonFlyBSD)
    --disable-sndio          # support the OpenBSD sndio (default auto)
    --disable-wasapi         # use the Windows Audio Session API (default auto)
    --disable-jack           # do not use jack (default auto)
    --disable-opensles       # Android OpenSL ES audio module (default disabled)
    --disable-tizen-audio    # Tizen audio module (default enabled on Tizen)
    --disable-samplerate     # Resampler with libsamplerate [default=auto]
    --disable-soxr           # SoX Resampler library [default=auto]
    --disable-kai            # support the K Audio Interface KAI (default enabled on OS/2)
    --disable-chromaprint    # (Chromaprint based audio fingerprinter) [default=auto]
    --disable-chromecast     # (Chromecast streaming support) [default=auto]


# Interface plugins:
    --disable-qt             # Qt UI support (default enabled)
    --disable-skins2         # skins interface module (default auto)
    --disable-libtar         # libtar support for skins2 (default auto)
    --disable-macosx         # Mac OS X gui support (default enabled on Mac OS X)
    --disable-sparkle        # Sparkle update support for OS X (default enabled on Mac OS X)
    --disable-minimal-macosx # Minimal Mac OS X support (default disabled)
    --disable-ncurses        # ncurses text-based interface (default auto)
    --disable-lirc           # lirc support (default disabled)
    --disable-srt            # SRT input/output plugin [default=auto]

# Visualisations and Video filter plugins:
    --disable-goom           # goom visualization plugin [default=auto]
    --disable-projectm       # projectM visualization plugin (default enabled)
    --disable-vsxu           # Vovoid VSXu visualization plugin (default auto)

# Service Discovery plugins:
    --disable-avahi          # Zeroconf services discovery [default=auto]
    --disable-udev           # Linux udev services discovery [default=auto]
    --disable-mtp            # MTP devices support [default=auto]
    --disable-upnp           # Intel UPNP SDK [default=auto]
    --disable-microdns       # mDNS services discovery [default=auto]

# Misc options:
    --disable-libxml2        # libxml2 support [default=auto]
    --disable-libgcrypt      # gcrypt support (default enabled)
    --disable-gnutls         # GNU TLS TLS/SSL support (default enabled)
    --disable-taglib         # do not use TagLib (default enabled)
    --disable-secret         # use libsecret for keystore [default=auto]
    --disable-kwallet        # use kwallet (via D-Bus) for keystore (default enabled)
    --disable-update-check   # update checking system (default disabled)
    --disable-osx-notifications  # macOS notification plugin (default disabled)
    --disable-notify         # libnotify notification [default=auto]
    --disable-libplacebo     # disable libplacebo support (default auto)
)

lazy_configure \
    --host="${ARCH}-apple-darwin" \
    --with-contrib="${ROOT_DIR}"  \
    --prefix="${ROOT_DIR}"  \
    ${CONFIGURE_FLAGS[@]}

make -j ${PROC_NUM}
make install
