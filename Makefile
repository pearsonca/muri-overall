SHELL=/bin/sh

RPATH=/usr/bin/Rscript

DATAPATH=./input
RESPATH=./output
PREPATH=../montreal-digest
SIMPATH=../scala-commsim
DIGESTPATH=../montreal-reprocess
START=/target/start

RDT=rdata
RDS=rds
JSN=json

.PHONY: starts clean-scala clean-rdata clean-rds simulate convenience

convenience: $(RESPATH)/location_lifetimes.png $(DATAPATH) $(RESPATH)

$(SIMPATH)$(START): $(SIMPATH)/src
	@cd $(SIMPATH); sbt start-script

$(DIGESTPATH)$(START): $(DIGESTPATH)/src
	@cd $(DIGESTPATH); sbt start-script

$(DATAPATH):
	ln -s $(in) $(DATAPATH)

$(RESPATH):
	ln -s $(out) $(RESPATH)

starts: $(SIMPATH)$(START) $(DIGESTPATH)$(START)

clean-scala:
	rm -f $(SIMPATH)$(START)
	rm -f $(DIGESTPATH)$(START)

clean-rdata:
	rm -i $(DATAPATH)/*-data.$(RDT)

clean-rds:
	rm -i $(DATAPATH)/*.$(RDS)

$(DATAPATH)/%.$(RDT): $(PREPATH)/%-data.R
	@cd $(PREPATH); $(RPATH) $<

$(DATAPATH)/users.Rdata: $(DATAPATH)/lifetimeGroups.Rdata $(DATAPATH)/fourierPowerGroups.Rdata $(DATAPATH)/vMFGroups.Rdata




$(DATAPATH)/%.$(RDS): $(PREPATH)/%-dt.R
	$(RPATH) $^ $@

$(DATAPATH)/raw-input.$(RDS): $(DATAPATH)/merged.o

$(DATAPATH)/filtered-input.$(RDS): $(DATAPATH)/raw-input.$(RDS) $(DATAPATH)/assumptions.$(JSN)

$(DATAPATH)/remap-location-ids.$(RDS) $(DATAPATH)/remap-user-ids.$(RDS): $(DATAPATH)/filtered-input.$(RDS)

$(DATAPATH)/remapped-input.$(RDS): $(DATAPATH)/remap-location-ids.$(RDS) $(DATAPATH)/remap-user-ids.$(RDS) $(DATAPATH)/filtered-input.$(RDS)




$(RESPATH)/%.png: $(PREPATH)/%-plot.R
	$(RPATH) $^ $@

$(RESPATH)/location_lifetimes.png: $(DATAPATH)/remapped-input.$(RDS)



simulate: $(SIMPATH)$(START)
	@cd $(SIMPATH); ./$(START) input/$(userfile) $(location) $(shape) $(freq)

process: $(DIGESTPATH)$(START)
	@cd $(DIGESTPATH); ./$(START) $(ARGS)
