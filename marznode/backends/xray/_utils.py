"""xray utilities"""

import re
import subprocess
from typing import Dict


def get_version(xray_path: str) -> str | None:
    """
    get xray version by running its executable
    :param xray_path:
    :return: xray version
    """
    cmd = [xray_path, "version"]
    output = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode()
    match = re.match(r"^Xray (\d+\.\d+\.\d+)", output)
    if match:
        return match.group(1)
    return None


def parse_x25519_output(output: str) -> Dict[str, str] | None:
    """Parse `xray x25519` stdout for both pre-25 and 26.x labels."""
    private = None
    public = None
    for raw_line in output.splitlines():
        if ":" not in raw_line:
            continue
        label, _, value = raw_line.partition(":")
        value = value.strip()
        if not value:
            continue
        normalized = label.strip().lower().replace(" ", "")
        if normalized in {"privatekey", "private_key"}:
            private = value
        elif normalized in {"publickey", "password"} or "publickey" in normalized:
            public = value
    if private and public:
        return {"private_key": private, "public_key": public}
    return None


def get_x25519(xray_path: str, private_key: str = None) -> Dict[str, str] | None:
    """
    get x25519 public key using the private key
    :param xray_path:
    :param private_key:
    :return: x25519 publickey
    """
    cmd = [xray_path, "x25519"]
    if private_key:
        cmd.extend(["-i", private_key])
    output = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode("utf-8")
    return parse_x25519_output(output)
