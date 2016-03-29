ifndef ROOT_DIR
$(error Do not use this makefile directly)
endif

.PHONY: figures-pdf figures-png tables

EXPORT_FORMATS = pdf png
EXPORT_TARGETS = $(foreach fmt,${EXPORT_FORMATS},figures-${fmt}) tables

tables: $(foreach ds,${DATASETS},exports/table_main_${ds}_pass_10000.tex) \
	exports/table_default_transitions_human_pcr_1_pass_1000.tex \
	exports/table_train_stop_human_pcr_1_pass_1000.tex

define make_table_main
# 1: ds
# 2: ss
exports/table_main_${1}_${2}.tex: \
	${1}.${2}.summary.main.map_pos.tsv \
	${1}.${2}.summary.main.errors.tsv \
	${1}.${2}.summary.main.runtime.tsv \
	| exports
	SGE_RREQ="-N $$@ -l h_tvmem=10G" :; \
	{ \
	  ROOT_DIR="${ROOT_DIR}" PYTHON3=${PYTHON3} ${ROOT_DIR}/opt-pack-tex-summary $$^ | \
	  column -t; \
	} >$$@ 2>.$$(patsubst exports/%,%,$$@).log
endef
$(foreach dss,${DATASUBSETS},\
$(foreach ds,$(call get_dss_ds,${dss}),\
$(foreach ss,$(call get_dss_ss,${dss}),\
$(eval $(call make_table_main,${ds},${ss})))))

define make_table_transition_params
# 1: ds
# 2: ss
exports/table_default_transitions_${1}_${2}.tex: \
	${1}.${2}.summary.default_transitions.map_pos.tsv \
	${1}.${2}.summary.default_transitions.errors.tsv \
	${1}.${2}.summary.default_transitions.runtime.tsv \
	| exports
	SGE_RREQ="-N $$@ -l h_tvmem=10G" :; \
	{ \
	  ROOT_DIR="${ROOT_DIR}" PYTHON3=${PYTHON3} ${ROOT_DIR}/opt-pack-tex-summary $$^ | \
	  cut -f 3-11,14 | \
	  column -t; \
	} >$$@ 2>.$$(patsubst exports/%,%,$$@).log
endef
$(foreach dss,${DATASUBSETS},\
$(foreach ds,$(call get_dss_ds,${dss}),\
$(foreach ss,$(call get_dss_ss,${dss}),\
$(eval $(call make_table_transition_params,${ds},${ss})))))

define make_table_train_stop
# 1: ds
# 2: ss
exports/table_train_stop_${1}_${2}.tex: \
	${1}.${2}.summary.train_stop.map_pos.tsv \
	${1}.${2}.summary.train_stop.errors.tsv \
	${1}.${2}.summary.train_stop.runtime.tsv \
	| exports
	SGE_RREQ="-N $$@ -l h_tvmem=10G" :; \
	{ \
	  ROOT_DIR="${ROOT_DIR}" PYTHON3=${PYTHON3} ${ROOT_DIR}/opt-pack-tex-summary $$^ | \
	  cut -f 3- | \
	  column -t; \
	} >$$@ 2>.$$(patsubst exports/%,%,$$@).log
endef
$(foreach dss,${DATASUBSETS},\
$(foreach ds,$(call get_dss_ds,${dss}),\
$(foreach ss,$(call get_dss_ss,${dss}),\
$(eval $(call make_table_train_stop,${ds},${ss})))))

# $(foreach ds,${DATASETS},exports/${ds}.pass_10000.summary.main.tex) \
# exports/human_pcr_1.pass_1000.summary.default_transitions.tex \
# exports/human_pcr_1.pass_1000.summary.train_stop.tex \
# exports/human_pcr_1.pass_1000.summary.threads.tex \
# exports/n_vs_m_scale.png

# define make_summary_tex
# exports/${1}.${2}.summary.${3}.tex: \
# 	${1}.${2}.summary.${3}.map_pos.tsv \
# 	${1}.${2}.summary.${3}.errors.tsv \
# 	${1}.${2}.summary.${3}.runtime.tsv
# 	SGE_RREQ="-N $$@ -l h_tvmem=10G" :; \
# 	${ROOT_DIR}/tex-summary-main $$^ >$$@ 2>.${1}.${2}.summary.${3}.tex.log
# endef
# $(foreach dss,${DATASUBSETS},\
# $(foreach ds,$(call get_dss_ds,${dss}),\
# $(foreach ss,$(call get_dss_ss,${dss}),\
# $(foreach opt_pack,$(call get_tag_list,nanocall_opt_pack,${ds}),\
# $(eval $(call make_summary_tex,${ds},${ss},${opt_pack}))))))

exports:
	mkdir -p exports

define make_detailed_figures
# 1: output format
figures-${1}: exports/n_vs_m_scale.${1}
exports/n_vs_m_scale.${1}: \
	$(foreach rp,${DETAILED_FIGURES_RUNS},${rp}.bam.summary.tsv ${rp}.params_table.tsv) \
	| exports
	SGE_RREQ="-N $$@ -l h_tvmem=10G" :; \
	{ \
	  cd exports && \
	  ${PYTHON3} ${ROOT_DIR}/make-plots --format "${1}" \
	    $(foreach rp,${DETAILED_FIGURES_RUNS},-d "$(call get_ds_name,$(word 1,$(subst ., ,${rp})))" ${PWD}/${rp}.{bam.summary,params_table}.tsv); \
	}
endef
$(foreach fmt,${EXPORT_FORMATS},$(eval $(call make_detailed_figures,${fmt})))