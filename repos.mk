# remote source for all repos
GITREF := https://github.com/pearsonca/

# the relevant repos
DIGEST   := montreal-digest
SIMULATE := scala-commsim
FILTER   := montreal-reprocess
DETECT   := montreal-detect

REPOS := $(DIGEST) $(SIMULATE) $(FILTER) $(DETECT)
REPODIRS := $(addprefix ../,$(REPOS))

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

ifndef iodirs
$(error repos.mk requires iodirs function be defined)
endif

$(foreach repo,$(REPODIRS),$(eval $(call iodirs,$(repo))))
