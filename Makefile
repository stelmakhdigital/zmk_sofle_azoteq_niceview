.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: build clean source freeze start all

PROJECT ?= zmk_sofle_niceview
BASE_DIR := ${PWD}
ZMK_APP_DIR ?= zmk/app
ZEPHYR_DIR ?= ${PWD}/zephyr
FIRMWARE_DIR ?= firmware

DZMK_CONFIG="${PWD}/config"
DSHIELD_LEFT ?= azoteq_sofle_left
DSHIELD_RIGHT ?= azoteq_sofle_right
DSHIELD_DONGLE ?= azoteq_sofle_dongle

MAIN_BOARD ?= nice_nano_v2

export BOARD_ROOT := ${PWD}

default: help
help: Makefile
	@echo "\n Choose a command run in "$(PROJECT)" project:"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'

## * make freeze - зафиксировать зависимости PIP в requirements.txt;
freeze:
	. venv/bin/activate && \
	pip freeze > ${BASE_DIR}/requirements.txt

_build_l:
	west build -d build/left -s ${ZMK_APP_DIR} -b ${MAIN_BOARD} -- \
	-DSHIELD="azoteq_sofle_left nice_view" \
	-DZMK_CONFIG=${DZMK_CONFIG}
	mkdir -p ${FIRMWARE_DIR}
	cp build/left/zephyr/zmk.uf2 ${FIRMWARE_DIR}/azoteq_sofle_left_${MAIN_BOARD}.uf2

_build_r:
	west build -d build/right -s ${ZMK_APP_DIR} -b ${MAIN_BOARD} -- \
	-DSHIELD="azoteq_sofle_right nice_view" \
	-DZMK_CONFIG=${DZMK_CONFIG}
	mkdir -p ${FIRMWARE_DIR}
	cp build/right/zephyr/zmk.uf2 ${FIRMWARE_DIR}/azoteq_sofle_right_${MAIN_BOARD}.uf2

_build_reset:
	west build -d build/reset -s ${ZMK_APP_DIR} -b ${MAIN_BOARD} -- -DSHIELD="settings_reset" -DZMK_CONFIG=${DZMK_CONFIG}
	mkdir -p ${FIRMWARE_DIR}
	cp build/reset/zephyr/zmk.uf2 ${FIRMWARE_DIR}/azoteq_sofle_reset_${MAIN_BOARD}.uf2

_clear_all:
	rm -rf .west build ${FIRMWARE_DIR} .cache .config ~/Library/Caches/zephyr/

_clear:
	rm -rf .west build ${FIRMWARE_DIR}

## * make all - build all firmwares (left, right, reset);
all: _clear _env _build_l _build_r _build_reset


_first_init:
	brew update && \
	brew install --cask gcc-arm-embedded && \
	brew install cmake ninja gperf python3 ccache qemu dtc wget libmagic && \
	python3 -m venv venv
 
_install_west:
	. venv/bin/activate && \
	pip install --upgrade pip && \
	pip install pyelftools && \
	pip install west && \
	git clone https://github.com/zmkfirmware/zmk.git && \
	cd zmk && \
	west init -l app && \
	west update && \
	pip install -r ./zephyr/scripts/requirements-extras.txt && \
	west zephyr-export && \
	west list
	cd ..

_init_env_values:
	chmod +x setup_env.sh && \
	chmod +x env_activate.sh && \
	./setup_env.sh

_env:
	./env_activate.sh

## * make start - initial project setup (venv, west, zephyr env);
start: _first_init _install_west _init_env_values



print:
	@echo "azoteq_sofle_left.overlay"
	@echo '```'
	@cat boards/shields/azoteq_sofle/azoteq_sofle_left.overlay
	@echo '```'
	@echo "\n"
	@echo "azoteq_sofle_right.overlay"
	@echo '```'
	@cat boards/shields/azoteq_sofle/azoteq_sofle_right.overlay
	@echo '```'
	@echo "\n"
	@echo "azoteq_sofle.dtsi"
	@echo '```'
	@cat boards/shields/azoteq_sofle/azoteq_sofle.dtsi
	@echo '```'
	@echo "\n"
