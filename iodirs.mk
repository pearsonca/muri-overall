# define this projects shared input / output directories
include references.mk

ifndef INDIR
$(error repos.mk requires INDIR variable be defined)
endif

ifndef OUTDIR
$(error repos.mk requires OUTDIR variable be defined)
endif

# provide targets for making them
# must be invoked as TAR=..somepath.. make (input|output)
$(INDIR):
	ln -shf $(TAR) $@

$(OUTDIR):
	ln -shf $(TAR) $@

# provide definitions to link other directories within this project
# to the shared directories
# gist: have input / output dirs in "overall" project directory
# link to where data actually lives (e.g., dropbox file, large external drive)
# then related repos just link to the overall projects links
define iodirs
$(1)/$(notdir $(INDIR)): | $(1) $(INDIR)
	ln -shf $(INDIR) $@

$(1)/$(notdir $(OUTDIR)): | $(1) $(OUTDIR)
	ln -shf $(OUTDIR) $@
endef
