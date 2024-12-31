FROM tensorflow/tensorflow:2.4.2-gpu

# ENV https_proxy "http://10.0.0.13:7890"
# ENV http_proxy "http://10.0.0.13:7890"


#RUN apt-get install -y wget && apt-key del 7fa2af80 && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb && dpkg -i cuda-keyring_1.0-1_all.deb
RUN apt-key del 7fa2af80 && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub


# System packages.
RUN apt-get update && apt-get install -y \
  ffmpeg \
  libgl1-mesa-dev \
  python3-pip \
  unrar \
  git \
  wget \
  && apt-get clean

# MuJoCo.
ENV MUJOCO_GL egl
RUN mkdir -p /root/.mujoco && \
  wget -nv https://www.roboti.us/download/mujoco200_linux.zip -O mujoco.zip && \
  unzip mujoco.zip -d /root/.mujoco && \
  rm mujoco.zip

# cmake 3.1.2
RUN wget https://github.com/Kitware/CMake/releases/download/v3.21.3/cmake-3.21.3-linux-x86_64.sh -O /tmp/cmake.sh && \
    chmod +x /tmp/cmake.sh && \
    /tmp/cmake.sh --prefix=/usr/local --skip-license && \
    rm /tmp/cmake.sh


# bazel
RUN wget -qO - https://bazel.build/bazel-release.pub.gpg | apt-key add - && \
    echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    apt-get update && apt-get install -y bazel && \
    rm -rf /var/lib/apt/lists/*

# Python packages.
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir \
  'gym[atari]==0.18.0' \
  atari_py \
  ruamel.yaml==0.16.13 \
  tensorflow_probability==0.12.2

# Atari ROMS.
RUN wget -L -nv http://www.atarimania.com/roms/Roms.rar && \
  unrar x Roms.rar && \
  python3 -m atari_py.import_roms ROMS && \
  rm -rf Roms.rar ROMS.zip ROMS


# MuJoCo key.
ARG MUJOCO_KEY=""
RUN echo "$MUJOCO_KEY" > /root/.mujoco/mjkey.txt
RUN cat /root/.mujoco/mjkey.txt

# DreamerV2.
ENV TF_XLA_FLAGS --tf_xla_auto_jit=2
COPY . /app
WORKDIR /app
CMD [ \
  "python3", "dreamerv2/train.py", \
  "--logdir", "/logdir/$(date +%Y%m%d-%H%M%S)", \
  "--configs", "defaults", "atari", \
  "--task", "atari_pong" \
]

