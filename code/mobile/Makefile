# Pet Trail mobile - adb reverse + flutter run
#
# Uso (na pasta mobile):
#   make run                  # local: adb reverse + flutter run (APIs no localhost)
#   make run-cloud            # cloud: flutter run usando URLs do dart_defines.json
#   make run DEVICE=emulator-5554
#   make run-pick             # sempre abre menu de dispositivos
#   make reverse              # reverse em todos os dispositivos
#   make flutter-devices      # lista dispositivos Flutter

API_PORT := 3001
WORKER_PORT := 3002
CHAT_PORT := 3003

PS_REVERSE := scripts/adb-reverse.ps1
PS_RUN     := scripts/flutter-run.ps1
SH_REVERSE := scripts/adb-reverse.sh
SH_RUN     := scripts/flutter-run.sh

# make run DEVICE=emulator-5554
DEVICE ?=
PICK ?=
SKIP_REVERSE ?=

RUN_ARGS :=
ifneq ($(DEVICE),)
  RUN_ARGS += -Device $(DEVICE)
endif
ifeq ($(PICK),1)
  RUN_ARGS += -Pick
endif
ifeq ($(SKIP_REVERSE),1)
  RUN_ARGS += -SkipReverse
endif

ifeq ($(OS),Windows_NT)
  RUN_REVERSE = powershell -NoProfile -ExecutionPolicy Bypass -File $(PS_REVERSE) -Action reverse
  RUN_LIST    = powershell -NoProfile -ExecutionPolicy Bypass -File $(PS_REVERSE) -Action list
  RUN_CLEAN   = powershell -NoProfile -ExecutionPolicy Bypass -File $(PS_REVERSE) -Action clean
  RUN_APP     = powershell -NoProfile -ExecutionPolicy Bypass -File $(PS_RUN) $(RUN_ARGS)
else
  RUN_REVERSE = bash $(SH_REVERSE) reverse
  RUN_LIST    = bash $(SH_REVERSE) list
  RUN_CLEAN   = bash $(SH_REVERSE) clean
  RUN_APP     = DEVICE="$(DEVICE)" PICK="$(PICK)" SKIP_REVERSE="$(SKIP_REVERSE)" bash $(SH_RUN)
endif

.PHONY: help reverse list clean devices flutter-devices run run-cloud run-pick

help:
	@echo Pet Trail mobile
	@echo.
	@echo   make reverse              Reverse portas $(API_PORT) $(WORKER_PORT) $(CHAT_PORT) (todos)
	@echo   make list                 Lista dispositivos adb e reverses
	@echo   make clean                Remove reverses
	@echo   make flutter-devices      Lista dispositivos Flutter
	@echo   make run                  Reverse + flutter run (menu se 2+ devices)
	@echo   make run DEVICE=ID        Roda no dispositivo escolhido
	@echo   make run-pick             Menu interativo de dispositivos
	@echo   make run SKIP_REVERSE=1   Roda sem aplicar reverse
	@echo.
	@echo Exemplo:
	@echo   make run DEVICE=emulator-5554
	@echo   make run DEVICE=RXCW3071CYP

devices list:
	@$(RUN_LIST)

reverse:
	@$(RUN_REVERSE)

clean:
	@$(RUN_CLEAN)

flutter-devices:
	@flutter devices

run:
	@$(RUN_APP)

run-cloud:
	@$(MAKE) run SKIP_REVERSE=1

run-pick:
	@$(MAKE) run PICK=1
