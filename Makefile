build_files:
	flutter pub run build_runner build
run_macos:
	flutter run --dart-define-from-file=env.json -d macos
