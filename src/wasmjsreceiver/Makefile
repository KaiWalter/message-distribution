main.wasm: src/*
	slight buildjs -e slightjs_engine.wasm -o main.wasm src/main.js

.PHONE:
run: main.wasm
	slight -c slightfile.toml run main.wasm -l
