
DATADIR := 'input'

TEMPLATEDIR := $(DATADIR)/simtemplates

PEAKDIMS := $(TEMPLATEDIR)/peaktime
USEDIMS := $(TEMPLATEDIR)/usage
VARDIMS := $(TEMPLATEDIR)/variability
SIZEDIMS := $(TEMPLATEDIR)/sizes

PEAKS := $(wildcard $(PEAKDIMS)/*)
USES := $(wildcard $(USEDIMS)/*)
VARS := $(wildcard $(VARDIMS)/*)
SIZES := $(wildcard $(SIZEDIMS)/*)

SIMPATH := ../scala-commsim
SIM := $(SIMPATH)/target/start

DIGPATH := ../montreal-digest
MKUSERS := $(DIGPATH)/mk_users.R

include bg-parse.mk

PARSED := input/user.RData input/censor.RData input/userPrefs.RData input/locClusters.RData input/loc_probs.csv

# in this rule, % is intended to be 001, 002, ... - sample ids
define simsrc
output/simsdata/$(1)/$(2)/$(3)/$(4)/%.src: $(MKUSERS) $(1) $(2) $(3) $(4) | output/simsdata/$(1)/$(2)/$(3)/$(4)/
	@echo use $^ to make $@
	$(RPATH) $^ $* > $@
	@touch $@
endef

define simout
output/simsdata/$(1)/$(2)/$(3)/$(4)/%.csv: $(SIM) $(1) $(2) $(3) $(4) | output/simsdata/$(1)/$(2)/$(3)/$(4)/
	@echo use $^ to make $@
	@touch $@
endef
