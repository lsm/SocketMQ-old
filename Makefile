
test:
	@./node_modules/.bin/mocha \
		--compilers coffee:coffee-script \
		--reporter spec

watch:
	@./node_modules/.bin/mocha \
		--watch \
		--compilers coffee:coffee-script \
		--reporter spec

.PHONY: test