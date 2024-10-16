assets/universal-sentence-encoder.tflite:
	mkdir -p assets
	curl -L -o assets/universal-sentence-encoder.tflite https://storage.googleapis.com/mediapipe-models/text_embedder/universal_sentence_encoder/float32/latest/universal_sentence_encoder.tflite
deps: assets/universal-sentence-encoder.tflite
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
