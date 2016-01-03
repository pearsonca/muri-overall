SHELL = /bin/sh

SIMPATH=../scala-commsim
DIGESTPATH=../montreal-process

$(SIMPATH)/target/start: $(SIMPATH)/src
	@cd $(SIMPATH); sbt start-script

$(DIGESTPATH)/target/start: $(DIGESTPATH)/src
	@cd $(DIGESTPATH); sbt start-script

.PHONY: starts clean simulate

starts: $(SIMPATH)/target/start $(DIGESTPATH)/target/start

clean:
	rm $(SIMPATH)/target/start
	rm $(DIGESTPATH)/target/start

stage:
	# do stuff with generating input csvs

simulate: $(SIMPATH)/target/start
	@cd $(SIMPATH); target/start input/$(userfile) $(location) $(shape) $(freq)

process: $(DIGESTPATH)/target/start
	@cd $(DIGESTPATH)
	@target/start $(ARGS)
