all: clean format check test


.PHONY:clean
clean:
	gleam clean

.PHONY:format
format:
	gleam format

.PHONY:check
check:
	gleam check

.PHONY:test
test:
	gleam "test"

