FROM python:3.12-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libssl-dev \
    libminizip-dev \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Build zsign from project submodule at image build time.
WORKDIR /build
COPY Zsign /build/Zsign
RUN cd /build/Zsign/build/linux && make -j$(nproc) && install -m755 /build/Zsign/bin/zsign /usr/local/bin/zsign

WORKDIR /app
COPY services/bootstrap-signer /app
RUN pip install --no-cache-dir -r requirements.txt

ENV BOOTSTRAP_PUBLIC_URL=https://api.defiancesign.com
ENV BOOTSTRAP_WORK_ROOT=/tmp/defiancesign-bootstrap
ENV BOOTSTRAP_IPA_URL=https://github.com/macdirtycow/DefianceSign/releases/download/v1.1.4/DefianceSign.ipa
ENV BOOTSTRAP_APP_VERSION=1.1.4
ENV BOOTSTRAP_CORS_ORIGINS=https://defiancesign.com,https://www.defiancesign.com

RUN mkdir -p /tmp/defiancesign-bootstrap && chmod 700 /tmp/defiancesign-bootstrap

EXPOSE 8787
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8787"]
