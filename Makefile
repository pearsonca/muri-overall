SHELL=/bin/sh

RPATH=/usr/bin/Rscript

GITREF := https://github.com/pearsonca/

DATAPATH   := ./input
RESPATH    := ./output
PREPATH    := ../montreal-digest
SIMPATH    := ../scala-commsim
DIGESTPATH := ../montreal-reprocess
START      := /target/start

RDT := rdata
RDS := rds
JSN := json
IMG := png

.PHONY: starts clean-scala clean-rdata clean-rds simulate convenience updates

convenience: $(DATAPATH) $(RESPATH) $(PREPATH) $(DATAPATH)/training-locations.$(RDS)

updates:
	git pull
	@cd $(PREPATH); git pull; ln -s $(in) $(DATAPATH); ln -s $(out) $(RESPATH)
	@cd $(DIGESTPATH); git pull; ln -s $(in) $(DATAPATH); ln -s $(out) $(RESPATH)
	@cd $(SIMPATH); git pull; ln -s $(in) $(DATAPATH); ln -s $(out) $(RESPATH)

$(PREPATH):
	@cd ..; git clone $(GITREF)montreal-digest.git

$(SIMPATH)/src:
	@cd ..; git clone $(GITREF)scala-commsim.git

$(DIGESTPATH)/src:
	@cd ..; git clone $(GITREF)montreal-reprocess.git

$(SIMPATH)$(START): $(shell find $(SIMPATH)/src -type f)
	@cd $(SIMPATH); sbt start-script;

$(DIGESTPATH)$(START): $(shell find $(DIGESTPATH)/src -type f)
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

$(DATAPATH)/paired.o: $(DATAPATH)/merged.o

$(DATAPATH)/raw-pairs.$(RDS): $(DATAPATH)/paired.o

$(DATAPATH)/filtered-input.$(RDS): $(DATAPATH)/raw-input.$(RDS) $(DATAPATH)/assumptions.$(JSN)

$(DATAPATH)/remap-location-ids.$(RDS) $(DATAPATH)/remap-user-ids.$(RDS): $(DATAPATH)/filtered-input.$(RDS)

$(DATAPATH)/remapped-input.$(RDS): $(addprefix $(DATAPATH)/,$(addsuffix .$(RDS), remap-location-ids remap-user-ids filtered-input))

$(DATAPATH)/location-lifetimes.$(RDS): $(DATAPATH)/remapped-input.$(RDS)

$(DATAPATH)/training-locations.$(RDS): $(DATAPATH)/remap-location-ids.$(RDS) $(DATAPATH)/parameters.$(JSN)

$(DATAPATH)/location-peaks.$(RDS): $(DATAPATH)/training-locations.$(RDS) $(DATAPATH)/remapped-input.$(RDS)








$(DATAPATH)/source-sample-%.$(RDS): $(PREPATH)/sample-events.R $(DATAPATH)/remapped-input.$(RDS)
	$(RPATH) $^ $* $@

SAMPLEINTERVALS := 1 2 3 4 5
RUNS := $(wildcard $(RESPATH)/run-*)

$(RESPATH)/run-%/: $(RESPATH)/run-%.pbs $(SIMPATH)$(START)
	rm -fr $@ && mkdir $@
	@cd $(SIMPATH); $<

$(RESPATH)/process-%/: $(RESPATH)/process-%.pbs $(DIGESTPATH)$(START) $(RESPATH)/run-%/
	rm -fr $@ && mkdir $@
	@cd $(DIGESTPATH); $<

$(RESPATH)/analyze-%/: $(RESPATH)/analyze-%.pbs $(SIMPATH)/analyze.R $(SIMPATH)$(START) $(RESPATH)/analyze-%/ $(DATAPATH)/raw-input.$(RDS) $(DATAPATH)/raw-pairs.$(RDS)
	rm -fr $@ && mkdir $@
	@cd $(DIGESTPATH); $<

source-samples: $(foreach i,$(SAMPLEINTERVALS),$(DATAPATH)/source-sample-$(i).$(RDS))

define sample-events-template
$(1)/sample-events-%/: $(DIGESTPATH)/sample-synthetic-events.R
	$(RPATH) $$^ $$* $$@
endef

$(foreach r,$(RUNS),$(eval $(call sample-events-template,$(r))))










$(RESPATH)/%.$(IMG): $(PREPATH)/%-plot.R
	$(RPATH) $^ $@

$(RESPATH)/location-lifetimes.$(IMG) $(RESPATH)/location-creation-rate.$(IMG) $(RESPATH)/location-life-distro.$(IMG): $(DATAPATH)/location-lifetimes.$(RDS)


simulate: $(SIMPATH)$(START)
	@cd $(SIMPATH); ./$(START) input/$(userfile) $(location) $(shape) $(freq)

process: $(DIGESTPATH)$(START)
	@cd $(DIGESTPATH); ./$(START) $(ARGS)
