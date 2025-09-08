# code to create validation analysis script
library(Strategus) # need https://github.com/OHDSI/Strategus/tree/v1.0-plpv-mt-modules branch


targetId <- 19684 # ATLAS id for target cohort
outcomeId <- 19683 # ATLAS id for outcome cohort
predictorIds <- c(19685,19695,19687,19690,19686,19691) # ATLAS ids for predictors
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
  runInclusionStatistics = FALSE,
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

# Restrict Data Settings to every 6 months --------------------------------
generateRestrictDataSettings <- function(start, end, interval = months(6)) {
  startDate <- lubridate::ymd(start)
  endDate <- lubridate::ymd(end)
  
  settingsList <- list()
  currentStart <- startDate
  
  while (currentStart < endDate) {
    currentEnd <- currentStart + interval - days(1)
    
    if (currentEnd > endDate) {
      currentEnd <- endDate
    }
    
    settings <- createRestrictPlpDataSettings(
      studyStartDate = format(currentStart, "%Y%m%d"),
      studyEndDate = format(currentEnd, "%Y%m%d")
    )
    
    settingsList <- append(settingsList, list(settings))
    currentStart <- currentStart + interval
  }
  
  return(settingsList)
  
}

restrictPlpDataSettings <- generateRestrictDataSettings("2010-01-01", "2025-06-01")

# PatientLevelPredictionValidation -------------------------------
createPackageModel <- function(modelFolder, package){
  result <- list(
    type = 'package',
    modelFolder = modelFolder,
    package = package
  )
  class(result) <- 'plpModel'
  
  return(result)
}
validationList <- list()

# Code to validate 3 models
validationList[[length(validationList) + 1]] <- PatientLevelPrediction::createValidationDesign(
  targetId = targetId,
  outcomeId = outcomeId,
  populationSettings = NULL, # use models
  restrictPlpDataSettings = restrictPlpDataSettings,
  plpModelList = list(
    createPackageModel(
      modelFolder = 'models/original_rcri',
      package = 'RCRIvalidation'
    )), # list of locations of models
  recalibrate = "weakRecalibration"
)
validationList[[length(validationList) + 1]] <- PatientLevelPrediction::createValidationDesign(
  targetId = targetId,
  outcomeId = outcomeId,
  populationSettings = NULL, # use models
  restrictPlpDataSettings = restrictPlpDataSettings,
  plpModelList = list(
    createPackageModel(
      modelFolder = 'models/recalibrated_rcri',
      package = 'RCRIvalidation'
    )),
  recalibrate = "weakRecalibration"
)
validationList[[length(validationList) + 1]] <- PatientLevelPrediction::createValidationDesign(
  targetId = targetId,
  outcomeId = outcomeId,
  populationSettings = NULL, # use models
  restrictPlpDataSettings = restrictPlpDataSettings,
  plpModelList = list(
    createPackageModel(
      modelFolder = 'models/mdcalc_rcri',
      package = 'RCRIvalidation'
    )),
  recalibrate = "weakRecalibration"
)

allValList <- do.call('c', validationList)

plpValModuleSettingsCreator <- PatientLevelPredictionValidationModule$new()
plpValModuleSpecifications <- plpValModuleSettingsCreator$createModuleSpecifications(
  allValList
)

# Create analysis specifications CDM modules ---------------
analysisSpecifications <- createEmptyAnalysisSpecificiations() |>
  addSharedResources(cohortSharedResourcesSpecifications) |>
  addCohortDiagnosticsModuleSpecifications(cdModuleSpecifications) |>
  addCohortGeneratorModuleSpecifications(cgModuleSpecifications) |>
  addPatientLevelPredictionValidationModuleSpecifications(plpValModuleSpecifications)

ParallelLogger::saveSettingsToJson(
  object = analysisSpecifications,
  fileName = "inst/study_execution_jsons/validation.json"
)
