#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_dir="${repo_root}/.zmk-workspace"
venv_dir="${repo_root}/.venv"
config_src_dir="${repo_root}/config"
config_work_dir="${workspace_dir}/config"
output_dir="${repo_root}/firmware"

board="nice_nano_v2"
targets=("left" "right")
force_update=0

usage() {
  cat <<'EOF'
Usage: scripts/build-zmk.sh [all|left|right] [--update]

Build local ZMK firmware for this config repo.

Options:
  all       Build both halves (default)
  left      Build the left half only
  right     Build the right half only
  --update  Refresh west modules before building
EOF
}

parse_args() {
  local positional=()
  while (($#)); do
    case "$1" in
      all)
        positional=("all")
        ;;
      left|right)
        positional+=("$1")
        ;;
      --update)
        force_update=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  if ((${#positional[@]} == 0)); then
    targets=("left" "right")
  elif [[ "${positional[0]}" == "all" ]]; then
    targets=("left" "right")
  else
    targets=("${positional[@]}")
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

find_arm_gcc() {
  local preferred="/opt/homebrew/opt/arm-none-eabi-gcc/bin/arm-none-eabi-gcc"

  if [[ -x "${preferred}" ]]; then
    echo "${preferred}"
    return 0
  fi

  command -v arm-none-eabi-gcc
}

setup_venv() {
  require_cmd python3

  if [[ ! -x "${venv_dir}/bin/python" ]]; then
    python3 -m venv "${venv_dir}"
  fi

  "${venv_dir}/bin/python" -m pip install --quiet --upgrade pip west
}

sync_config() {
  rm -rf "${config_work_dir}"
  mkdir -p "${config_work_dir}"
  cp -R "${config_src_dir}/." "${config_work_dir}/"
}

setup_workspace() {
  mkdir -p "${workspace_dir}"
  sync_config

  if [[ ! -d "${workspace_dir}/.west" ]]; then
    (
      cd "${workspace_dir}"
      "${venv_dir}/bin/west" init -l config
    )
    force_update=1
  fi

  if ((force_update)) || [[ ! -d "${workspace_dir}/zmk" ]] || [[ ! -d "${workspace_dir}/zephyr" ]]; then
    (
      cd "${workspace_dir}"
      "${venv_dir}/bin/west" update
      "${venv_dir}/bin/west" zephyr-export
    )
    "${venv_dir}/bin/python" -m pip install --quiet -r "${workspace_dir}/zephyr/scripts/requirements.txt"
  else
    (
      cd "${workspace_dir}"
      "${venv_dir}/bin/west" zephyr-export
    )
  fi
}

build_target() {
  local side="$1"
  local shield="cradio_${side}"
  local build_dir="${workspace_dir}/build/${side}"
  local output_file="${output_dir}/${shield}-${board}.uf2"
  local arm_gcc toolchain_bin toolchain_root binutils_bin

  arm_gcc="$(find_arm_gcc)"
  toolchain_bin="$(dirname "${arm_gcc}")"
  binutils_bin="/opt/homebrew/opt/arm-none-eabi-binutils/bin"

  if [[ "${arm_gcc}" == /opt/homebrew/opt/arm-none-eabi-gcc/bin/arm-none-eabi-gcc ]]; then
    toolchain_root="/opt/homebrew"
  else
    toolchain_root="$(cd "${toolchain_bin}/.." && pwd)"
  fi

  mkdir -p "${output_dir}"

  (
    cd "${workspace_dir}"
    export PATH="${toolchain_bin}:${PATH}"
    if [[ -d "${binutils_bin}" ]]; then
      export PATH="${binutils_bin}:${PATH}"
    fi
    export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
    export GNUARMEMB_TOOLCHAIN_PATH="${toolchain_root}"
    ZMK_EXTRA_MODULES="${repo_root}" \
      "${venv_dir}/bin/west" build -p always -s zmk/app -d "${build_dir}" -b "${board}" -- \
      -DZMK_CONFIG="${config_work_dir}" \
      -DZMK_EXTRA_MODULES="${repo_root}" \
      -DSHIELD="${shield}"
  )

  cp "${build_dir}/zephyr/zmk.uf2" "${output_file}"
  echo "Built ${shield}: ${output_file}"
}

main() {
  parse_args "$@"

  require_cmd cmake
  require_cmd ninja
  require_cmd dtc
  find_arm_gcc >/dev/null

  setup_venv
  setup_workspace

  for target in "${targets[@]}"; do
    build_target "${target}"
  done
}

main "$@"
