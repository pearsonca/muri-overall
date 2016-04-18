SHELL=/bin/sh

RPATH=$(shell which Rscript)

GITREF := https://github.com/pearsonca/

DATAPATH   := ./input
RESPATH    := ./output
PREPATH    := ../montreal-digest
SIMPATH    := ../scala-commsim
DIGESTPATH := ../montreal-reprocess
DETECTPATH := ../montreal-detect
POSTER     := ../epi_research_day2016
START      := /target/start

REPOS := $(PREPATH) $(SIMPATH) $(DIGESTPATH) $(POSTER) $(DETECTPATH)

RDT := rdata
RDS := rds
JSN := json
IMG := png

.PHONY: starts clean-scala clean-rdata clean-rds simulate convenience updates status clean-pbs touchdates check-err

convenience: $(DATAPATH) $(RESPATH) $(PREPATH) $(DATAPATH)/training-locations.$(RDS)

define gpull
cd $(1); git pull;

endef

updates: $(REPOS)
	git pull
	$(foreach p,$^,$(call gpull, $(p)))

define gstatus
cd $(1); git status -uno;

endef

status: $(REPOS)
	git status -uno
	$(foreach p,$^,$(call gstatus, $(p)))

$(REPOS):
	cd .. && git clone $(GITREF)$(subst ../,,$@).git

%/src: %

$(SIMPATH)$(START): $(shell find $(SIMPATH)/src -type f)
	@cd $(SIMPATH); sbt start-script;

$(DIGESTPATH)$(START): $(shell find $(DIGESTPATH)/src -type f)
	@cd $(DIGESTPATH); sbt start-script

define link_data
cd $(1); ln -sf $(2)$(3);

endef

$(DATAPATH) $(RESPATH):
	$(eval TMP:=$(abspath $@))
	ln -sf $(tar) $@
#	$(foreach p, $^, $(call link_data,$(p),$(TMP), $@))

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

# understands % == (un)matched/
$(DATAPATH)/%-covert-in.csv:
	mkdir -p $(dir $@)
	$(PREPATH)/mk_users.R $(subst /, ,$*)$(if $(v), -v)

$(RESPATH)/%-covert-out.csv: $(SIMPATH)$(START) $(DATAPATH)/%-covert-in.csv
	mkdir -p $(dir $@)
	$^ $(if $(k),$(k),10) $(if $(mn),$(mn),7) $(if $(y),$(y),4) > $@

$(RESPATH)/%-covert-trans.csv: $(PREPATH)/translate.R $(DATAPATH)/remap-location-ids.$(RDS) $(RESPATH)/%-covert-out.csv
	$(RPATH) $^ $@ 20649600

$(RESPATH)/%-covert-cc.csv $(RESPATH)/%-covert-cu.csv: $(DIGESTPATH)$(START) $(RESPATH)/%-covert-trans.csv
	$^$(if $(window), $(window))
	# read in rds, remap user ids


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


$(DATAPATH)/reverse-location-id-map.csv: $(PREPATH)/reverse-location-id-map-csv.R $(DATAPATH)/remap-location-ids.$(RDS)
	$(RPATH) $^ $@






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


## SHARED PBS STUFF

clean-bg-%:
	rm -rf $(DATAPATH)/background-clusters/spin-glass/base-$*
	rm -rf $(DATAPATH)/background-clusters/spin-glass/acc-$*
	rm -rf $(DATAPATH)/background-clusters/spin-glass/agg-$*
	rm -rf $(DATAPATH)/background-clusters/spin-glass/pc-$*

%/background-clusters:
	mkdir $@

%/background-clusters/spin-glass: | %/background-clusters
	mkdir $@

PCL=10 # pre compute limit default

clean-pbs:
	rm *.pbs

check-err: checkpbserr.sh
	./$<

clean-hpc:
	rm *.err*
	rm *.o*


bg-spinglass-base-%.pbs: base_pbs.sh
	rm -f $@; touch $@
	./$< $@ $*

# this make target is a whole directory of files
$(DATAPATH)/background-clusters/spin-glass/base-%: $(PREPATH)/background-spinglass.R $(DATAPATH)/raw-pairs.$(RDS) | $(DATAPATH)/background-clusters/spin-glass
	mkdir -p $(dir $@)
	$(RPATH) $^ $(subst -, ,$(basename $(subst base-,,$(notdir $@)))) $@$(if $(PCL), -m $(PCL))


bg-spinglass-acc-%.pbs: acc_pbs.sh
	rm -f $@; touch $@
	./$< $@ $* $(strip $(shell ls $(DATAPATH)/background-clusters/spin-glass/base-$* | wc -l))

bg-spinglass-agg-%.pbs: agg_pbs.sh
	rm -f $@; touch $@
	./$< $@ $*

bg-spinglass-pc-%.pbs: pc_pbs.sh
	rm -f $@; touch $@
	./$< $@ $* $(strip $(shell ls $(DATAPATH)/background-clusters/spin-glass/agg-$* | wc -l))

touchdates:
	for d in $(DATAPATH)/background-clusters/spin-glass/pc-*; do touch $$d/*; done;
	for d in $(DATAPATH)/background-clusters/spin-glass/agg-*; do touch $$d/*; done;
	for d in $(DATAPATH)/background-clusters/spin-glass/acc-*; do touch $$d/*; done;
	for d in $(DATAPATH)/background-clusters/spin-glass/base-*; do touch $$d/*; done;

convenientqsub: # use like make convenientqsub tar=pc
	for f in *$(tar)*.pbs; do qsub $f; done;

%.pdf: %.Rmd
	R CMD Sweave $(notdir $*).Rmd && pdflatex $(notdir $*) && bibtex $(notdir $*) && pdflatex $(notdir $*) && pdflatex $(notdir $*) && open $(notdir $*).pdf

# $(POSTER)/%.pdf: $(POSTER)/%.Rnw $(POSTER)/*.bib
# 	cd $(POSTER) && R CMD Sweave $(notdir $*).Rnw && pdflatex $(notdir $*) && bibtex $(notdir $*) && pdflatex $(notdir $*) && pdflatex $(notdir $*) && open $(notdir $*).pdf


.SECONDEXPANSION:

# this make target is for individual files, corresponding to those in base-%
$(DATAPATH)/background-clusters/spin-glass/acc-%: $(PREPATH)/precompute-spinglass-persistence-scores.R $$(dir $(DATAPATH)/background-clusters/spin-glass/base-$$*)
	mkdir -p $(dir $@)
	$(RPATH) $^ $@


$(DATAPATH)/background-clusters/spin-glass/agg-%: $(PREPATH)/accumulate-spinglass-persistence-scores.R $$(subst agg,acc,$$@)*
	mkdir -p $(dir $@)
	$(RPATH) $< $(subst agg,acc,$(dir $@)) $@

$(DATAPATH)/background-clusters/spin-glass/pc-%: $(PREPATH)/spinglass-persistence-communities.R $(DATAPATH)/background-clusters/spin-glass/agg-%
	mkdir -p $(dir $@)
	$(RPATH) $^ $@

$(RESPATH)/background-clusters/spin-glass/plot-pc-%.png: $(PREPATH)/plot-persistence-communities.R $(DATAPATH)/background-clusters/spin-glass/pc-%/*
	$(RPATH) $> $(dir $(lastword $^)) $@

#$(DATAPATH)/background-clusters/spin-glass/%-pc.$(RDS): $(PREPATH)/spinglass-persistence-communities.R $(DATAPATH)/background-clusters/spin-glass/%-acc.$(RDS)
#	$(RPATH) $^ $@

$(RESPATH)/matched/: | $(RESPATH)/
	touch $@

$(RESPATH)/matched/mid/: | $(RESPATH)/matched/
	touch $@

$(RESPATH)/matched/mid/lo/: | $(RESPATH)/matched/mid/
	touch $@

$(RESPATH)/matched/mid/lo/late/: | $(RESPATH)/matched/mid/lo/
	touch $@

$(RESPATH)/matched/mid/lo/late/10/: | $(RESPATH)/matched/mid/lo/late/
	touch $@

$(RESPATH)/matched/mid/lo/late/10/001-covert-0/: | $(RESPATH)/matched/mid/lo/late/10/
	touch $@

$(RESPATH)/matched/mid/lo/late/10/001-covert-0-base.rds: $(DETECTPATH)/pre-spinglass-detect.R $(DATAPATH)/raw-pairs.rds $(DATAPATH)/raw-location-lifetimes.rds $(DATAPATH)/background-clusters/spin-glass/base-15-30 $(RESPATH)/matched/mid/lo/late/10/001-covert-0/ | $(RESPATH)/matched/mid/lo/late/10/001-covert-0-cc.csv $(RESPATH)/matched/mid/lo/late/10/001-covert-0-cu.csv
	$(RPATH) $^ $@

$(RESPATH)/matched/mid/lo/late/10/001-covert-0/%-acc.rds: $(DETECTPATH)/pre-spinglass-score.R $(DATAPATH)/background-clusters/spin-glass/base-15-30 $(RESPATH)/matched/mid/lo/late/10/001-covert-0-base.rds $(RESPATH)/matched/mid/lo/late/10/001-covert-0
	$(RPATH) $^

$(RESPATH)/matched/mid/lo/late/10/001-covert-0/%.rds: $(DETECTPATH)/spinglass-detect.R $(DATAPATH)/background-clusters/spin-glass/agg-15-30/%.rds $(DATAPATH)/background-clusters/spin-glass/pc-15-30/%.rds $(RESPATH)/matched/mid/lo/late/10/001-covert-0/%-acc.rds
	$(RPATH) $^

$(RESPATH)/matched/mid/med/: | $(RESPATH)/matched/mid/
	touch $@

$(RESPATH)/matched/mid/med/middle/: | $(RESPATH)/matched/mid/med/
	touch $@

$(RESPATH)/matched/mid/med/middle/10/: | $(RESPATH)/matched/mid/med/middle/
	touch $@

$(RESPATH)/matched/mid/med/middle/10/001-covert-0/: | $(RESPATH)/matched/mid/med/middle/10/
	touch $@

$(RESPATH)/matched/mid/med/middle/10/001-covert-0-base.rds: $(DETECTPATH)/pre-spinglass-detect.R $(DATAPATH)/raw-pairs.rds $(DATAPATH)/raw-location-lifetimes.rds $(DATAPATH)/background-clusters/spin-glass/base-15-30 $(RESPATH)/matched/mid/med/middle/10/001-covert-0/ | $(RESPATH)/matched/mid/med/middle/10/001-covert-0-cc.csv $(RESPATH)/matched/mid/med/middle/10/001-covert-0-cu.csv
	$(RPATH) $^ $@

$(RESPATH)/matched/mid/med/middle/10/001-covert-0/%-acc.rds: $(DETECTPATH)/pre-spinglass-score.R $(DATAPATH)/background-clusters/spin-glass/base-15-30 $(RESPATH)/matched/mid/med/middle/10/001-covert-0-base.rds $(RESPATH)/matched/mid/med/middle/10/001-covert-0
	$(RPATH) $^

$(RESPATH)/matched/mid/med/middle/10/001-covert-0/%.rds: $(DETECTPATH)/spinglass-detect.R $(DATAPATH)/background-clusters/spin-glass/agg-15-30/%.rds $(DATAPATH)/background-clusters/spin-glass/pc-15-30/%.rds $(RESPATH)/matched/mid/med/middle/10/001-covert-0/%-acc.rds
	$(RPATH) $^

$(RESPATH)/%.$(IMG): $(PREPATH)/%-plot.R
	$(RPATH) $^ $@

$(RESPATH)/location-lifetimes.$(IMG) $(RESPATH)/location-creation-rate.$(IMG) $(RESPATH)/location-life-distro.$(IMG): $(DATAPATH)/location-lifetimes.$(RDS)


simulate: $(SIMPATH)$(START)
	@cd $(SIMPATH); ./$(START) input/$(userfile) $(location) $(shape) $(freq)

process: $(DIGESTPATH)$(START)
	@cd $(DIGESTPATH); ./$(START) $(ARGS)
