# remote source for all repos
GITREF := https://github.com/pearsonca/

# the relevant repos
DIGEST   := montreal-digest
SIMULATE := scala-commsim
FILTER   := montreal-reprocess
DETECT   := montreal-detect

REPOS := $(DIGEST) $(SIMULATE) $(FILTER) $(DETECT)
REPODIRS := $(addprefix ../,$(REPOS))

default: updates

# make each repo by cloning
$(REPODIRS):
	cd .. && git clone $(GITREF)$(notdir $@).git

# go into a repo & pull
define gpull
(cd $(1) && git pull);
endef

# updates is an action, not a target
.PHONY: updates

updates: | $(REPODIRS)
	$(foreach rep,$|,$(call gpull,$(rep))) echo updates attempted

ifndef INDIR
$(error repos.mk requires INDIR variable be defined)
endif

ifndef OUTDIR
$(error repos.mk requires OUTDIR variable be defined)
endif

define iodirs
$(1)/$(notdir $(INDIR)): | $(1) $(INDIR)
	ln -shf $(INDIR) $@

$(1)/$(notdir $(OUTDIR)): | $(1) $(OUTDIR)
	ln -shf $(OUTDIR) $@
endef

$(foreach repo,$(REPODIRS),$(eval $(call iodirs,$(repo))))
