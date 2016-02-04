SHELL=/bin/sh

RPATH=/usr/bin/Rscript

GITREF=https://github.com/pearsonca/

DATAPATH=./input
RESPATH=./output
PREPATH=../montreal-digest
SIMPATH=../scala-commsim
DIGESTPATH=../montreal-reprocess
START=/target/start

RDT=rdata
RDS=rds
JSN=json
IMG=png

.PHONY: starts clean-scala clean-rdata clean-rds simulate convenience

convenience: $(DATAPATH) $(RESPATH) $(PREPATH) $(RESPATH)/location-creation-rate.$(IMG)

$(PREPATH):
	@cd ..; git clone $(GITREF)montreal-digest.git

$(SIMPATH)/src:
	@cd ..; git clone $(GITREF)scala-commsim.git

$(DIGESTPATH)/src:
	@cd ..; git clone $(GITREF)montreal-reprocess.git

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

clean-img:
	rm -i $(RESPATH)/*.$(IMG)




$(DATAPATH)/%.$(RDT): $(PREPATH)/%-data.R
	@cd $(PREPATH); $(RPATH) $<

$(DATAPATH)/users.Rdata: $(DATAPATH)/lifetimeGroups.Rdata $(DATAPATH)/fourierPowerGroups.Rdata $(DATAPATH)/vMFGroups.Rdata




$(DATAPATH)/%.$(RDS): $(PREPATH)/%-dt.R
	$(RPATH) $^ $@

$(DATAPATH)/raw-input.$(RDS): $(DATAPATH)/merged.o

$(DATAPATH)/filtered-input.$(RDS): $(DATAPATH)/raw-input.$(RDS) $(DATAPATH)/assumptions.$(JSN)

$(DATAPATH)/remap-location-ids.$(RDS) $(DATAPATH)/remap-user-ids.$(RDS): $(DATAPATH)/filtered-input.$(RDS)

$(DATAPATH)/remapped-input.$(RDS): $(DATAPATH)/remap-location-ids.$(RDS) $(DATAPATH)/remap-user-ids.$(RDS) $(DATAPATH)/filtered-input.$(RDS)

$(DATAPATH)/location-lifetimes.$(RDS): $(DATAPATH)/remapped-input.$(RDS)


$(RESPATH)/%.$(IMG): $(PREPATH)/%-plot.R
	$(RPATH) $^ $@

$(RESPATH)/location-lifetimes.$(IMG) $(RESPATH)/location-creation-rate.$(IMG): $(DATAPATH)/location-lifetimes.$(RDS)


simulate: $(SIMPATH)$(START)
	@cd $(SIMPATH); ./$(START) input/$(userfile) $(location) $(shape) $(freq)

process: $(DIGESTPATH)$(START)
	@cd $(DIGESTPATH); ./$(START) $(ARGS)
