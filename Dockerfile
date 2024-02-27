# 使用NVIDIA CUDA 12.0.0基础镜像
FROM nvidia/cuda:12.0.0-runtime-ubuntu22.04

# 安装Python、pip、git和OpenCV运行时必需的系统依赖
RUN apt-get update && \
    apt-get install --no-install-recommends -y python3 python3-pip git libgl1-mesa-glx libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

# 创建/app目录
RUN mkdir /app

# 设置工作目录
WORKDIR /app

# 创建并激活虚拟环境
RUN pip3 install virtualenv && \
    virtualenv /venv

# 使用cache mount来缓存pip安装，加速后续构建
# 注意：这一行现在移动到每个pip安装命令前，以确保使用缓存
# 安装和升级pip
RUN --mount=type=cache,target=/root/.cache/pip pip3 install --upgrade pip

# 为NVIDIA用户安装稳定版PyTorch
RUN --mount=type=cache,target=/root/.cache/pip . /venv/bin/activate && \
    pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121

# 复制requirements.txt到/app
COPY requirements.txt /app/requirements.txt

# 安装项目的其他依赖
RUN --mount=type=cache,target=/root/.cache/pip . /venv/bin/activate && \
    pip3 install -r requirements.txt

# 安装OpenCV（无头版本，适用于服务器和容器环境）
RUN --mount=type=cache,target=/root/.cache/pip . /venv/bin/activate && \
    pip3 install opencv-python-headless

# 复制项目文件到/app目录
COPY . /app/

# 安装custom_node目录下所有文件夹的依赖
RUN --mount=type=cache,target=/root/.cache/pip . /venv/bin/activate && \
    find /app/custom_nodes -type f -name 'requirements.txt' -exec pip3 install -r {} \;

# 执行custom_nodes/ComfyUI-Impact-Pack/install.py
RUN --mount=type=cache,target=/root/.cache/pip . /venv/bin/activate && \
    python3 custom_nodes/ComfyUI-Impact-Pack/install.py

# 设置容器启动时执行的命令
ENTRYPOINT ["bash", "-c", ". /venv/bin/activate && exec \"$@\"", "--"]
CMD ["python3", "main.py", "--listen", "0.0.0.0"]
