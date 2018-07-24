#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-default.mk)" "nbproject/Makefile-local-default.mk"
include nbproject/Makefile-local-default.mk
endif
endif

# Environment
MKDIR=gnumkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=cof
DEBUGGABLE_SUFFIX=cof
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=cof
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

ifeq ($(COMPARE_BUILD), true)
COMPARISON_BUILD=
else
COMPARISON_BUILD=
endif

ifdef SUB_IMAGE_ADDRESS

else
SUB_IMAGE_ADDRESS_COMMAND=
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=../ws2813-firmware/WS2813.asm colorize_analog.asm UtilRoutines.asm

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/_ext/739432619/WS2813.o ${OBJECTDIR}/colorize_analog.o ${OBJECTDIR}/UtilRoutines.o
POSSIBLE_DEPFILES=${OBJECTDIR}/_ext/739432619/WS2813.o.d ${OBJECTDIR}/colorize_analog.o.d ${OBJECTDIR}/UtilRoutines.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/_ext/739432619/WS2813.o ${OBJECTDIR}/colorize_analog.o ${OBJECTDIR}/UtilRoutines.o

# Source Files
SOURCEFILES=../ws2813-firmware/WS2813.asm colorize_analog.asm UtilRoutines.asm


CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-default.mk dist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

MP_PROCESSOR_OPTION=16f1615
MP_LINKER_DEBUG_OPTION= 
# ------------------------------------------------------------------------------------
# Rules for buildStep: assemble
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/_ext/739432619/WS2813.o: ../ws2813-firmware/WS2813.asm  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}/_ext/739432619" 
	@${RM} ${OBJECTDIR}/_ext/739432619/WS2813.o.d 
	@${RM} ${OBJECTDIR}/_ext/739432619/WS2813.o 
	@${FIXDEPS} dummy.d -e "${OBJECTDIR}/_ext/739432619/WS2813.err" $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE) -d__DEBUG -d__MPLAB_DEBUGGER_PK3=1 -q -p$(MP_PROCESSOR_OPTION)  -l\"${OBJECTDIR}/_ext/739432619/WS2813.lst\" -e\"${OBJECTDIR}/_ext/739432619/WS2813.err\" $(ASM_OPTIONS)    -o\"${OBJECTDIR}/_ext/739432619/WS2813.o\" \"../ws2813-firmware/WS2813.asm\" 
	@${DEP_GEN} -d "${OBJECTDIR}/_ext/739432619/WS2813.o"
	@${FIXDEPS} "${OBJECTDIR}/_ext/739432619/WS2813.o.d" $(SILENT) -rsi ${MP_AS_DIR} -c18 
	
${OBJECTDIR}/colorize_analog.o: colorize_analog.asm  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/colorize_analog.o.d 
	@${RM} ${OBJECTDIR}/colorize_analog.o 
	@${FIXDEPS} dummy.d -e "${OBJECTDIR}/colorize_analog.err" $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE) -d__DEBUG -d__MPLAB_DEBUGGER_PK3=1 -q -p$(MP_PROCESSOR_OPTION)  -l\"${OBJECTDIR}/colorize_analog.lst\" -e\"${OBJECTDIR}/colorize_analog.err\" $(ASM_OPTIONS)    -o\"${OBJECTDIR}/colorize_analog.o\" \"colorize_analog.asm\" 
	@${DEP_GEN} -d "${OBJECTDIR}/colorize_analog.o"
	@${FIXDEPS} "${OBJECTDIR}/colorize_analog.o.d" $(SILENT) -rsi ${MP_AS_DIR} -c18 
	
${OBJECTDIR}/UtilRoutines.o: UtilRoutines.asm  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/UtilRoutines.o.d 
	@${RM} ${OBJECTDIR}/UtilRoutines.o 
	@${FIXDEPS} dummy.d -e "${OBJECTDIR}/UtilRoutines.err" $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE) -d__DEBUG -d__MPLAB_DEBUGGER_PK3=1 -q -p$(MP_PROCESSOR_OPTION)  -l\"${OBJECTDIR}/UtilRoutines.lst\" -e\"${OBJECTDIR}/UtilRoutines.err\" $(ASM_OPTIONS)    -o\"${OBJECTDIR}/UtilRoutines.o\" \"UtilRoutines.asm\" 
	@${DEP_GEN} -d "${OBJECTDIR}/UtilRoutines.o"
	@${FIXDEPS} "${OBJECTDIR}/UtilRoutines.o.d" $(SILENT) -rsi ${MP_AS_DIR} -c18 
	
else
${OBJECTDIR}/_ext/739432619/WS2813.o: ../ws2813-firmware/WS2813.asm  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}/_ext/739432619" 
	@${RM} ${OBJECTDIR}/_ext/739432619/WS2813.o.d 
	@${RM} ${OBJECTDIR}/_ext/739432619/WS2813.o 
	@${FIXDEPS} dummy.d -e "${OBJECTDIR}/_ext/739432619/WS2813.err" $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE) -q -p$(MP_PROCESSOR_OPTION)  -l\"${OBJECTDIR}/_ext/739432619/WS2813.lst\" -e\"${OBJECTDIR}/_ext/739432619/WS2813.err\" $(ASM_OPTIONS)    -o\"${OBJECTDIR}/_ext/739432619/WS2813.o\" \"../ws2813-firmware/WS2813.asm\" 
	@${DEP_GEN} -d "${OBJECTDIR}/_ext/739432619/WS2813.o"
	@${FIXDEPS} "${OBJECTDIR}/_ext/739432619/WS2813.o.d" $(SILENT) -rsi ${MP_AS_DIR} -c18 
	
${OBJECTDIR}/colorize_analog.o: colorize_analog.asm  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/colorize_analog.o.d 
	@${RM} ${OBJECTDIR}/colorize_analog.o 
	@${FIXDEPS} dummy.d -e "${OBJECTDIR}/colorize_analog.err" $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE) -q -p$(MP_PROCESSOR_OPTION)  -l\"${OBJECTDIR}/colorize_analog.lst\" -e\"${OBJECTDIR}/colorize_analog.err\" $(ASM_OPTIONS)    -o\"${OBJECTDIR}/colorize_analog.o\" \"colorize_analog.asm\" 
	@${DEP_GEN} -d "${OBJECTDIR}/colorize_analog.o"
	@${FIXDEPS} "${OBJECTDIR}/colorize_analog.o.d" $(SILENT) -rsi ${MP_AS_DIR} -c18 
	
${OBJECTDIR}/UtilRoutines.o: UtilRoutines.asm  nbproject/Makefile-${CND_CONF}.mk
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/UtilRoutines.o.d 
	@${RM} ${OBJECTDIR}/UtilRoutines.o 
	@${FIXDEPS} dummy.d -e "${OBJECTDIR}/UtilRoutines.err" $(SILENT) -c ${MP_AS} $(MP_EXTRA_AS_PRE) -q -p$(MP_PROCESSOR_OPTION)  -l\"${OBJECTDIR}/UtilRoutines.lst\" -e\"${OBJECTDIR}/UtilRoutines.err\" $(ASM_OPTIONS)    -o\"${OBJECTDIR}/UtilRoutines.o\" \"UtilRoutines.asm\" 
	@${DEP_GEN} -d "${OBJECTDIR}/UtilRoutines.o"
	@${FIXDEPS} "${OBJECTDIR}/UtilRoutines.o.d" $(SILENT) -rsi ${MP_AS_DIR} -c18 
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: link
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
dist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_LD} $(MP_EXTRA_LD_PRE)   -p$(MP_PROCESSOR_OPTION)  -w -x -u_DEBUG -z__ICD2RAM=1 -m"${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map"   -z__MPLAB_BUILD=1  -z__MPLAB_DEBUG=1 -z__MPLAB_DEBUGGER_PK3=1 $(MP_LINKER_DEBUG_OPTION) -odist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${OUTPUT_SUFFIX}  ${OBJECTFILES_QUOTED_IF_SPACED}     
else
dist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_LD} $(MP_EXTRA_LD_PRE)   -p$(MP_PROCESSOR_OPTION)  -w  -m"${DISTDIR}/${PROJECTNAME}.${IMAGE_TYPE}.map"   -z__MPLAB_BUILD=1  -odist/${CND_CONF}/${IMAGE_TYPE}/space-fuzz-pedal.${IMAGE_TYPE}.${DEBUGGABLE_SUFFIX}  ${OBJECTFILES_QUOTED_IF_SPACED}     
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r build/default
	${RM} -r dist/default

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(shell mplabwildcard ${POSSIBLE_DEPFILES})
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
