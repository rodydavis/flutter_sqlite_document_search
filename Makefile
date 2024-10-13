deps:
	cd third_party/sqlite-vec && ./scripts/vendor.sh
	cd third_party/sqlite-vec && make sqlite-vec.h
	cd third_party/sqlite-vec && make all
	cd third_party/sqlite-vec/bindings/dart && make deps
build_files:
	flutter pub run build_runner build
run_chrome:
	flutter run --dart-define-from-file=env.json -d chrome
run_macos:
	flutter run --dart-define-from-file=env.json -d macos
run_windows:
	flutter run --dart-define-from-file=env.json -d windows
run_linux:
	flutter run --dart-define-from-file=env.json -d linux
