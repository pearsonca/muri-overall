SHELL=/bin/sh

RPATH=/usr/bin/Rscript

GITREF := https://github.com/pearsonca/

DATAPATH   := ./input
RESPATH    := ./output
PREPATH    := ../montreal-digest
SIMPATH    := ../scala-commsim
DIGESTPATH := ../montreal-reprocess
POSTER     := ../epi_research_day2016
START      := /target/start

RDT := rdata
RDS := rds
JSN := json
IMG := png

.PHONY: starts clean-scala clean-rdata clean-rds simulate convenience updates status

convenience: $(DATAPATH) $(RESPATH) $(PREPATH) $(DATAPATH)/training-locations.$(RDS)

updates: $(POSTER) $(PREPATH) $(SIMPATH) $(DIGESTPATH)
	git pull
	cd $(PREPATH); git pull;
	cd $(DIGESTPATH); git pull;
	cd $(SIMPATH); git pull;
	cd $(POSTER); git pull;

status:
	git status -uno
	cd $(PREPATH); git status -uno;
	cd $(DIGESTPATH); git status -uno;
	cd $(SIMPATH); git status -uno;
	cd $(POSTER); git status -uno;

$(POSTER) $(PREPATH) $(SIMPATH) $(DIGESTPATH):
	cd .. && git clone $(GITREF)$(subst ../,,$@).git && cd $(subst ../,,$@) && ln -s $(in) $(DATAPATH) && ln -s $(out) $(RESPATH)

%/src: %

$(SIMPATH)$(START): $(shell find $(SIMPATH)/src -type f)
	@cd $(SIMPATH); sbt start-script;

$(DIGESTPATH)$(START): $(shell find $(DIGESTPATH)/src -type f)
	@cd $(DIGESTPATH); sbt start-script

define link_data
cd $(1); ln -sf $(2)$(3);

endef

$(DATAPATH) $(RESPATH): $(POSTER) $(PREPATH) $(SIMPATH) $(DIGESTPATH)
	touch $@
	$(eval TMP:=$(abspath $@))
	ln -sf $(tar) $@
	$(foreach p, $^, $(call link_data,$(p),$(TMP), $@))

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





~/.Renviron: Makefile
	@touch $@
	@if grep -Fxq "GITPROJHOME=$(realpath ../)" $@; then echo ".Renviron already contains GITPROJHOME."; else printf 'GITPROJHOME=%s\n' $(realpath ../) >> $@; fi

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

$(DATAPATH)/raw-location-lifetimes.$(RDS): $(DATAPATH)/raw-input.$(RDS)

$(DATAPATH)/location-lifetimes.$(RDS): $(DATAPATH)/raw-location-lifetimes.$(RDS) $(DATAPATH)/remap-location-ids.$(RDS)

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

## TODO: rather than processing on a one-by-one basis, convert all eligible items at once since script will support inputs

define run-samples-template
$(1)%-cc.$(RDS) $(1)%-cu.$(RDS): $(DIGESTPATH)/rbinarize.R $(1)%-cc.csv $(1)%-cu.csv
	$(RPATH) $$^

$(1)all-converted: $(foreach cstar, $(wildcard $(1)*-c*.csv), $(subst csv,rds,$(cstar)))

.PHONY: $(1)all-converted
endef

$(foreach r, $(wildcard $(RESPATH)/process-*/), $(eval $(call run-samples-template, $(r))))

#$(RESPATH)/process-%/combined.$(RDS): $(DIGESTPATH)/synthesize.R $(RESPATH)/process-%/*cc.csv $(RESPATH)/process-%/*cu.csv
#	$(RPATH) $^

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






$(POSTER)/%.pdf: $(POSTER)/%.Rnw $(POSTER)/*.bib
	cd $(POSTER) && R CMD Sweave $(notdir $*).Rnw && pdflatex $(notdir $*) && bibtex $(notdir $*) && pdflatex $(notdir $*) && pdflatex $(notdir $*) && open $(notdir $*).pdf
