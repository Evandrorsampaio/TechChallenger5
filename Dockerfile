# Llama 3.2 3B + Chroma. Sem FakeChatModel.
# torch CUDA vem da imagem base; o pip abaixo não reinstala torch.
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PERFIL_EXECUCAO=full-gpu \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    HF_HOME=/cache/huggingface \
    HUGGINGFACE_HUB_CACHE=/cache/huggingface

WORKDIR /app

# A imagem base aponta o apt para a porta 80. Nesse host a conexão é recusada;
# os mesmos espelhos em HTTPS respondem.
RUN set -eux; \
    find /etc/apt -name 'sources.list' -o -name '*.sources' -o -name '*.list' \
      | while read -r fonte; do \
          sed -i \
            -e 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g' \
            -e 's|http://security.ubuntu.com|https://security.ubuntu.com|g' \
            "$fonte"; \
        done; \
    printf 'Acquire::Retries "5";\nAcquire::https::Timeout "30";\n' > /etc/apt/apt.conf.d/80retries; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential; \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt requirements-ml.txt requirements-llm.txt requirements-full.txt ./
RUN pip install --no-cache-dir --upgrade-strategy only-if-needed \
        -r requirements.txt \
        -r requirements-ml.txt \
        -r requirements-llm.txt \
        -r requirements-full.txt \
    && python -c "import torch; assert torch.version.cuda, 'pip trocou o torch CUDA por um wheel de CPU'"

COPY lib ./lib
COPY scripts ./scripts
COPY referencias ./referencias
COPY pyproject.toml .env.example ./
COPY artifacts/metrics ./artifacts/metrics
COPY artifacts/models ./artifacts/models
COPY artifacts/data ./artifacts/data
COPY artifacts/rag ./artifacts/rag
COPY files ./files

EXPOSE 7860

CMD ["python", "scripts/app_full.py"]
