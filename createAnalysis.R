# code to create validation analysis script

targetId <- 19684 # ATLAS id for target cohort
outcomeId <- 19683 # ATLAS id for outcome cohort
predictorIds <- c(19695, 19685, 19687, 19690, 19691) # ATLAS ids for predictors
#remotes::install_github('ohdsi/Strategus', ref = 'v1.0-plpv-mt-modules')
library(Strategus)
ROhdsiWebApi::authorizeWebApi(
  baseUrl = Sys.getenv('baseUrl'), 
  authMethod = 'windows', 
  webApiUsername = keyring::key_get('webApiUsername', 'all'), 
  webApiPassword =  keyring::key_get('webApiPassword', 'all')
    )

# get the cohort ids from ATLAS used as the target, outcome and predictors
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  cohortIds = c(targetId, outcomeId, predictorIds), 
  generateStats = T,
  baseUrl = Sys.getenv('baseUrl')
  )


# Cohort Diagnostics -----------------
cdModuleSettingsCreator <- CohortDiagnosticsModule$new()
cdModuleSpecifications <- cdModuleSettingsCreator$createModuleSpecifications(
  runInclusionStatistics = TRUE,
  runIncludedSourceConcepts = TRUE,
  runOrphanConcepts = TRUE,
  runTimeSeries = FALSE,
  runVisitContext = TRUE,
  runBreakdownIndexEvents = TRUE,
  runIncidenceRate = TRUE,
  runCohortRelationship = TRUE,
  runTemporalCohortCharacterization = TRUE
)

# Cohort Generator -----------------
cgModuleSettingsCreator <- CohortGeneratorModule$new()

# Create the settings & validate them
cohortSharedResourcesSpecifications <- cgModuleSettingsCreator$createCohortSharedResourceSpecifications(cohortDefinitionSet)
cgModuleSettingsCreator$validateCohortSharedResourceSpecifications(cohortSharedResourcesSpecifications)

cgModuleSpecifications <- cgModuleSettingsCreator$createModuleSpecifications()


# ModelTransferModule - this will take a model in the github and download it
# need a different spec for people who do not have internet access when 
# running a study
transferSettingsCreator <- Strategus::ModelTransferModule$new()
transferModuleSpecifications <- transferSettingsCreator$createModuleSpecifications(
  githubSettings = list(
    
    # create the original model and save to repos inst/models/original_rcri folder
    list(
      githubUser = 'ohdsi-studies',
      githubRepository = 'RCRIvalidation',
      githubBranch = 'main',
      githubModelsFolder = 'models',
      githubModelFolder = 'original_rcri'
    ),
    
    # create the recalibrated model and save to repos inst/models/recalibrated_rcri folder
    list(
      githubUser = 'ohdsi-studies',
      githubRepository = 'RCRIvalidation',
      githubBranch = 'main',
      githubModelsFolder = 'models',
      githubModelFolder = 'recalibrated_rcri'
    ),
    
    
    # create OMOPed model and save to repos inst/models/omoped_rcri folder
    list(
      githubUser = 'ohdsi-studies',
      githubRepository = 'RCRIvalidation',
      githubBranch = 'main',
      githubModelsFolder = 'models',
      githubModelFolder = 'omoped_rcri'
    )
    
  )
)

# PatientLevelPredictionValidation -------------------------------
# This lets you specify settings to run on all the models transferred using 
# the model transfer module
plpValModuleSettingsCreator <- PatientLevelPredictionValidationModule$new()
plpValModuleSpecifications <- plpValModuleSettingsCreator$createModuleSpecifications(
  list(
    # for each model in the model transfer we will apply to the different settings
    
    # setting 1: 
  list(
    targetId = targetId,
    oucomeId = outcomeId,
    restrictPlpDataSettings = PatientLevelPrediction::createRestrictPlpDataSettings(), # vector
    validationSettings = PatientLevelPrediction::createValidationSettings(
      recalibrate = "weakRecalibration"
    )
  )
  
  # could add a different t/o setting 
  #,
  #list(targetId = ...)

  )
)


# Create analysis specifications CDM modules ---------------
analysisSpecifications <- createEmptyAnalysisSpecificiations() |>
  addSharedResources(cohortSharedResourcesSpecifications) |>
  addCohortDiagnosticsModuleSpecifications(cdModuleSpecifications) |>
  addCohortGeneratorModuleSpecifications(cgModuleSpecifications) |>
  addModelTransferModuleSpecifications(transferModuleSpecifications)
  addPatientLevelPredictionValidationModuleSpecifications(plpValModuleSpecifications)

ParallelLogger::saveSettingsToJson(
  object = analysisSpecifications,
  fileName = "inst/analysisSpecifications.json"
)
