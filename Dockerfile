FROM tobyxdd/hysteria:v2 AS hysteria-image

# Official GitHub musl tarball has no with_v2ray_api; marznode stats need it.
FROM golang:1.25-alpine AS sing-box-build
ARG SING_BOX_VERSION=1.14.0
ARG TARGETARCH
RUN apk add --no-cache git ca-certificates
WORKDIR /src
RUN git clone --depth 1 --branch "v${SING_BOX_VERSION}" https://github.com/SagerNet/sing-box.git .
ENV CGO_ENABLED=0
RUN GOARCH="${TARGETARCH}" go build -trimpath \
      -ldflags "-s -w -X github.com/sagernet/sing-box/constant.Version=${SING_BOX_VERSION}" \
      -tags "with_gvisor,with_quic,with_dhcp,with_wireguard,with_utls,with_acme,with_clash_api,with_v2ray_api" \
      -o /out/sing-box ./cmd/sing-box

FROM python:3.12-alpine

ENV PYTHONUNBUFFERED=1

ARG XRAY_VERSION=26.3.27
ARG TARGETARCH

COPY --from=hysteria-image /usr/local/bin/hysteria /usr/local/bin/hysteria
COPY --from=sing-box-build /out/sing-box /usr/local/bin/sing-box

WORKDIR /app

COPY . .

RUN mkdir /etc/init.d/

RUN set -eux; \
    apk add --no-cache curl unzip tar; \
    ARCH="${TARGETARCH}"; \
    if [ -z "${ARCH}" ]; then \
      case "$(uname -m)" in \
        x86_64) ARCH=amd64 ;; \
        aarch64) ARCH=arm64 ;; \
        *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;; \
      esac; \
    fi; \
    case "${ARCH}" in \
      amd64) XRAY_ASSET=Xray-linux-64.zip ;; \
      arm64) XRAY_ASSET=Xray-linux-arm64-v8a.zip ;; \
      *) echo "unsupported xray arch: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/xray.zip \
      "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/${XRAY_ASSET}"; \
    mkdir -p /tmp/xray /usr/local/lib/xray /usr/share/xray; \
    unzip -o /tmp/xray.zip -d /tmp/xray; \
    install -m 0755 /tmp/xray/xray /usr/local/bin/xray; \
    cp /tmp/xray/geoip.dat /tmp/xray/geosite.dat /usr/local/lib/xray/; \
    cp /tmp/xray/geoip.dat /tmp/xray/geosite.dat /usr/share/xray/; \
    rm -rf /tmp/xray /tmp/xray.zip; \
    apk add --no-cache alpine-sdk libffi-dev; \
    pip install --no-cache-dir -r /app/requirements.txt; \
    apk del -r alpine-sdk libffi-dev curl unzip

CMD ["python3", "marznode.py"]
