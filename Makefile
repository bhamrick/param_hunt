all: param_hunt.gb

param_hunt.o: param_hunt.s
	wla-gb -o param_hunt.o param_hunt.s

param_hunt.gb: param_hunt.o linkfile
	wlalink linkfile param_hunt.gb

clean:
	rm param_hunt.o param_hunt.gb
