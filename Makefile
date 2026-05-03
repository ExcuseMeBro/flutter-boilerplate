.PHONY: bootstrap analyze test check clean

bootstrap:
	flutter pub get

analyze:
	flutter analyze

test:
	flutter test

check: bootstrap analyze test

clean:
	flutter clean
	flutter pub get
