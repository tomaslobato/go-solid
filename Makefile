.PHONY: build dev run setup

setup: 
	./setup.sh

dev:
	(cd client && pnpm dev) & (cd server && air)

build: 
	rm -rf bin
	mkdir bin
	cd server && cp .env ../bin/.env && go build -o ../bin/main . && \
	cd ../client && pnpm build

run: bin
	cd bin && ./main