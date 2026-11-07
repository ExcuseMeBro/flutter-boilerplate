.PHONY: bootstrap analyze test check clean

bootstrap:
	flutter pub get --enforce-lockfile

analyze:
	flutter analyze --no-pub

test:
	flutter test --no-pub
	python3 -m unittest discover -s scripts -p 'test_*.py' -v

check: bootstrap analyze test

clean:
	flutter clean
	flutter pub get --enforce-lockfile
